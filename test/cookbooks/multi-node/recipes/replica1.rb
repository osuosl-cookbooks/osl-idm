hostname 'replica1.testing.osuosl.org' do
  ipaddress '10.1.0.3'
end

osl_ipa_client 'primary.testing.osuosl.org' do
  domain 'testing.osuosl.org'
  principal 'admin'
  password 'admin_password'
end

osl_ipa_server 'primary.testing.osuosl.org' do
  domain 'testing.osuosl.org'
  realm 'TESTING.OSUOSL.ORG'
  dirsrv_password 'dirsrv_password'
  admin_password 'admin_password'
  certificate 'wildcard'
  certificate_pin '1234'
  replica true
end
