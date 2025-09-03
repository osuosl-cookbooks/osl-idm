osl_noggin 'default' do
  freeipa_servers %w(idm.testing.osuosl.org)
  fernet_secret '-8Y6JVsS2a67PJ0ucTIAEVQT1KwgJcS5DWPnHp3GvgM='
  freeipa_admin_password 'admin_password'
  secret_key 'f9eef5765fa195857b94ba81f4c2855b72c24211401efc9949d1c742f385287d'
end
