resource_name :osl_ipa_client
provides :osl_ipa_client
unified_mode true

default_action :install

property :ipa_server, String, name_property: true
property :domain, String, required: true
property :principal, String, required: true
property :password, String, required: true, sensitive: true
property :mkhomedir, [true, false], default: true
property :ntp, [true, false], default: false
property :force_join, [true, false], default: false
property :fixed_primary, [true, false], default: true

action :install do
  package 'freeipa-client'

  execute 'ipa-client-install' do
    command [
      'ipa-client-install',
      '--unattended',
      "--server=#{new_resource.ipa_server}",
      "--domain=#{new_resource.domain}",
      "--principal=#{new_resource.principal}",
      "--password=#{new_resource.password}",
      "--realm=#{new_resource.domain.upcase}",
      (new_resource.mkhomedir ? '--mkhomedir' : nil),
      (new_resource.ntp ? nil : '--no-ntp'),
      (new_resource.force_join ? '--force-join' : nil),
      (new_resource.fixed_primary ? '--fixed-primary' : nil),
    ].compact.join(' ')
    sensitive true
    creates '/etc/ipa/default.conf'
  end
end

action :uninstall do
  command 'ipa-client-install --uninstall --unattended'
  only_if { ::File.exist?('/etc/ipa/default.conf') }
end
