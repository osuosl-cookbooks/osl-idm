resource_name :osl_keycloak
provides :osl_keycloak
unified_mode true

property :admin_password, String, sensitive: true, required: true
property :caddy, [true, false], default: false
property :db_engine, String, equal_to: %w(postgres mariadb), default: 'mariadb'
property :db_host, String, default: 'localhost'
property :db_name, String, default: 'keycloak'
property :db_pass, String, sensitive: true, required: true
property :db_user, String, default: 'keycloak'
property :hostname, String, name_property: true
property :keystore_pass, String, sensitive: true, required: true
property :port, Integer, default: 8080
property :version, String, default: '26.3'

default_action :create

action :create do
  osl_firewall_port 'http' do
    unless new_resource.caddy
      ports [new_resource.port]
    end
  end

  include_recipe 'osl-docker'

  osl_caddy 'keycloak' if new_resource.caddy

  osl_caddy_site new_resource.hostname do
    content(
      new_resource.hostname => {
        "reverse_proxy 127.0.0.1:#{new_resource.port}" => {
          'header_up' => [
            'X-Forwarded-Proto {scheme}',
            'X-Forwarded-For {remote_host}',
            'X-Forwarded-Host {host}',
          ],
        },
      }
    )
    notifies :reload, 'osl_caddy[keycloak]'
  end if new_resource.caddy

  docker_image 'quay.io/keycloak/keycloak' do
    tag new_resource.version
    notifies :build, "docker_image[keycloak-#{new_resource.hostname}]"
  end

  directory "/opt/keycloak/#{new_resource.name}" do
    recursive true
  end

  template "/opt/keycloak/#{new_resource.name}/Dockerfile" do
    cookbook 'osl-idm'
    sensitive true
    mode '0600'
    variables(
      db_engine: new_resource.db_engine,
      db_url: keycloak_db_url,
      db_user: new_resource.db_user,
      db_pass: new_resource.db_pass,
      hostname: new_resource.hostname
    )
    notifies :build, "docker_image[keycloak-#{new_resource.hostname}]"
  end

  docker_image "keycloak-#{new_resource.hostname}" do
    source "/opt/keycloak/#{new_resource.name}/Dockerfile"
    action :build_if_missing
    notifies :redeploy, "docker_container[#{new_resource.hostname}]"
  end

  docker_container new_resource.hostname do
    repo "keycloak-#{new_resource.hostname}"
    port "#{new_resource.port}:8080"
    restart_policy 'always'
    sensitive true
    command "start --optimized --hostname=https://#{new_resource.hostname} --http-enabled=true --proxy-headers xforwarded"
    env [
      'KC_BOOTSTRAP_ADMIN_USERNAME=admin',
      "KC_BOOTSTRAP_ADMIN_PASSWORD=#{new_resource.admin_password}",
    ]
  end
end
