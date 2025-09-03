resource_name :osl_noggin
provides :osl_noggin
unified_mode true

property :accept_images_from, Array, default: []
property :activation_token_expiration, Integer, default: 30
property :allowed_username_human, Array, default: ['a-z', '0-9', '-']
property :allowed_username_max_size, Integer, default: 32
property :allowed_username_min_size, Integer, default: 5
property :allowed_username_pattern, String, default: '^[a-z0-9][a-z0-9-]{3,30}[a-z0-9]$'
property :avatar_default_type, String, equal_to: %w(mp identicon monsterid wavatar retro robohash), default: 'robohash'
property :avatar_service_url, String, default: 'https://seccdn.libravatar.org/'
property :basset_url, String
property :fernet_secret, String, sensitive: true, required: true
property :freeipa_admin_password, String, sensitive: true, required: true
property :freeipa_admin_user, String, default: 'admin'
property :freeipa_servers, Array, required: true
property :gunicorn_opts, String
property :gunicorn_workers, String, default: '3'
property :mail_default_sender, String, default: "Noggin <noggin@#{node['domain']}>"
property :mail_domain_blocklist, Array, default: []
property :mail_suppress_send, [true, false], default: kitchen?
property :osl_only, [true, false], default: true
property :page_size, Integer, default: 30
property :password_reset_expiration, Integer, default: 10
property :registration_open, [true, false], default: true
property :secret_key, String, sensitive: true, required: true
property :spamcheck_token_expiration, Integer, default: 60
property :stage_users_role, String, default: 'Stage User Managers'
property :templates_custom_directories, Array, default: []
property :theme, String, default: 'default'

default_action :create

action :create do
  include_recipe 'osl-repos::epel'

  osl_firewall_port 'http' do
    ports [8000]
    osl_only new_resource.osl_only
  end

  package 'noggin'

  user 'noggin' do
    system true
    shell '/usr/sbin/nologin'
  end

  directory '/etc/noggin' do
    user 'noggin'
    group 'noggin'
  end

  directory '/var/log/noggin' do
    user 'noggin'
    group 'noggin'
  end

  osl_systemd_unit_drop_in 'bind' do
    unit_name 'noggin.service'
    content <<~EOF
      [Service]
      ExecStart=
      ExecStart=sh -c "gunicorn-3 -u noggin -g noggin ${GUNICORN_OPTS} -w ${GUNICORN_WORKERS} --env NOGGIN_CONFIG_PATH=/etc/noggin/noggin.cfg --access-logfile /var/log/noggin/access.log --error-logfile /var/log/noggin/error.log --bind tcp://0.0.0.0:8000 'noggin.app:create_app()'"
    EOF
  end

  template '/etc/sysconfig/noggin' do
    user 'noggin'
    group 'noggin'
    cookbook 'osl-idm'
    source 'noggin-sysconfig.erb'
    variables(
      gunicorn_opts: new_resource.gunicorn_opts,
      gunicorn_workers: new_resource.gunicorn_workers
    )
    notifies :restart, 'service[noggin]'
  end

  template '/etc/noggin/noggin.cfg' do
    user 'noggin'
    group 'noggin'
    cookbook 'osl-idm'
    sensitive true
    mode '0600'
    variables(
      accept_images_from: new_resource.accept_images_from,
      activation_token_expiration: new_resource.activation_token_expiration,
      allowed_username_human: new_resource.allowed_username_human,
      allowed_username_max_size: new_resource.allowed_username_max_size,
      allowed_username_min_size: new_resource.allowed_username_min_size,
      allowed_username_pattern: new_resource.allowed_username_pattern,
      avatar_default_type: new_resource.avatar_default_type,
      avatar_service_url: new_resource.avatar_service_url,
      basset_url: new_resource.basset_url,
      fernet_secret: new_resource.fernet_secret,
      freeipa_admin_password: new_resource.freeipa_admin_password,
      freeipa_admin_user: new_resource.freeipa_admin_user,
      freeipa_servers: new_resource.freeipa_servers.sort,
      mail_default_sender: new_resource.mail_default_sender,
      mail_domain_blocklist: new_resource.mail_domain_blocklist,
      mail_suppress_send: new_resource.mail_suppress_send,
      page_size: new_resource.page_size,
      password_reset_expiration: new_resource.password_reset_expiration,
      registration_open: new_resource.registration_open,
      secret_key: new_resource.secret_key,
      spamcheck_token_expiration: new_resource.spamcheck_token_expiration,
      stage_users_role: new_resource.stage_users_role,
      templates_custom_directories: new_resource.templates_custom_directories,
      theme: new_resource.theme
    )
    notifies :restart, 'service[noggin]'
  end

  service 'noggin' do
    action [:enable, :start]
  end
end
