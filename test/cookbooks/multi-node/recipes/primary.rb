hostname 'primary.testing.osuosl.org' do
  ipaddress '10.1.0.2'
end

osl_freeipa 'primary.testing.osuosl.org' do
  domain 'testing.osuosl.org'
  realm 'TESTING.OSUOSL.ORG'
  dirsrv_password 'dirsrv_password'
  admin_password 'admin_password'
  certificate 'wildcard'
  certificate_pin '1234'
end
