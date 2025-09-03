caddy = input('caddy')

control 'keycloak' do
  describe docker_container('keycloak.testing.osuosl.org') do
    it { should exist }
    it { should be_running }
    its('image') { should eq 'keycloak-keycloak.testing.osuosl.org:latest' }
    its('ports') { should include '8443/tcp, 0.0.0.0:8080->8080/tcp, 9000/tcp' }
    its('command') { should eq '/opt/keycloak/bin/kc.sh start --optimized --hostname=https://keycloak.testing.osuosl.org --http-enabled=true --proxy-headers xforwarded' }
  end

  describe docker_image('keycloak-keycloak.testing.osuosl.org') do
    it { should exist }
  end

  describe file('/opt/keycloak/keycloak.testing.osuosl.org/Dockerfile') do
    it { should exist }
    its('mode') { should cmp '0600' }
  end

  describe directory('/opt/keycloak/keycloak.testing.osuosl.org') do
    it { should exist }
  end

  describe port 8080 do
    it { should be_listening }
    its('processes') { should include 'docker-proxy' }
  end

  describe port 80 do
    it { should be_listening }
    its('processes') { should include 'caddy' }
  end if caddy

  describe port 443 do
    it { should be_listening }
    its('processes') { should include 'caddy' }
  end if caddy

  if caddy
    keycloak_url = 'https://keycloak.testing.osuosl.org'
  else
    keycloak_url = 'http://keycloak.testing.osuosl.org:8080'
  end

  access_token = json(content: inspec.command(
      "curl -k --silent -X POST #{keycloak_url}/realms/master/protocol/openid-connect/token " \
      "--data-urlencode 'grant_type=password' " \
      "--data-urlencode 'client_id=admin-cli' " \
      "--data-urlencode 'username=admin' " \
      "--data-urlencode 'password=admin_password'"
    ).stdout)['access_token']

  describe http("#{keycloak_url}/realms/master", ssl_verify: false) do
    its('status') { should eq 200 }
    its('body') { should include 'public_key' }
  end

  describe http("#{keycloak_url}/admin/realms/master",
    method: 'GET',
    ssl_verify: false,
    headers: {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{access_token}",
    }) do
    its('status') { should eq 200 }
    its('headers.Content-Type') { should cmp 'application/json;charset=UTF-8' }
  end

  describe json(content: http("#{keycloak_url}/admin/realms/master",
    method: 'GET',
    ssl_verify: false,
    headers: {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{access_token}",
    }).body) do
    its('realm') { should cmp 'master' }
    its('enabled') { should cmp true }
  end
end
