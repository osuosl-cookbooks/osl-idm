hostname 'keycloak.testing.osuosl.org'

append_if_no_line '/etc/hosts' do
  path '/etc/hosts'
  line "#{node['ipaddress']} keycloak.testing.osuosl.org"
end

osl_mysql_test 'keycloak' do
  username 'keycloak'
  password 'keycloak'
end

osl_keycloak 'keycloak.testing.osuosl.org' do
  admin_password 'admin_password'
  db_host node['ipaddress']
  db_pass 'keycloak'
  keystore_pass 'keystore_pass'
end
