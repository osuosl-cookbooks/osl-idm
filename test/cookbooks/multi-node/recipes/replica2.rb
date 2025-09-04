hostname 'replica2.testing.osuosl.org' do
  ipaddress '10.1.0.4'
end

osl_ipa_client 'primary.testing.osuosl.org' do
  domain 'testing.osuosl.org'
  principal 'admin'
  password 'admin_password'
end
