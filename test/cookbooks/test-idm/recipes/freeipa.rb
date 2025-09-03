hostname 'idm.testing.osuosl.org'

append_if_no_line '/etc/hosts' do
  path '/etc/hosts'
  line "#{node['ipaddress']} idm.testing.osuosl.org"
end

osl_freeipa 'idm.testing.osuosl.org' do
  domain 'testing.osuosl.org'
  realm 'TESTING.OSUOSL.ORG'
  dirsrv_password 'dirsrv_password'
  admin_password 'admin_password'
  certificate 'wildcard'
  certificate_pin '1234'
  dns true
  ntp true
end
