resource_name :osl_ipa_server
provides :osl_ipa_server
unified_mode true

default_action :install

property :admin_password, String, required: true, sensitive: true
property :certificate_pin, String, sensitive: true, required: true
property :certificate, String, required: true
property :dirsrv_password, String, required: true, sensitive: true
property :dns, [true, false], default: false
property :domain, String, required: true
property :ntp, [true, false], default: false
property :realm, String, required: true
property :replica, [true, false], default: false
property :server_hostname, String, name_property: true

action :install do
  node.override['base']['chrony']['conf'].tap do |c|
    c['port'] = 123
    c['allow'] = nil
  end if new_resource.ntp

  include_recipe 'base::chrony' if new_resource.ntp

  osl_firewall_port 'http'
  osl_firewall_port 'ldap'
  osl_firewall_kerberos 'ipa_server'
  osl_firewall_dns 'ipa_server' if new_resource.dns

  package %w(ipa-server ipa-healthcheck)
  package 'ipa-server-dns' if new_resource.dns

  certificate_manage new_resource.certificate do
    cert_file "#{new_resource.certificate}.crt"
    key_file  "#{new_resource.certificate}.key"
    chain_file "#{new_resource.certificate}.ca-bundle"
    notifies :run, "execute[create openssl pkcs12 #{new_resource.certificate}.p12]", :immediately
  end

  execute "create openssl pkcs12 #{new_resource.certificate}.p12" do
    command [
      "openssl pkcs12 -export -name 'httpd-ds-cert'",
      "-passout \"pass:#{new_resource.certificate_pin}\"",
      "-certfile /etc/pki/tls/certs/#{new_resource.certificate}.ca-bundle",
      "-inkey /etc/pki/tls/private/#{new_resource.certificate}.key",
      "-in /etc/pki/tls/certs/#{new_resource.certificate}.crt",
      "-out /etc/pki/tls/certs/#{new_resource.certificate}.p12",
    ].compact.join(' ')
    sensitive true
    creates "/etc/pki/tls/certs/#{new_resource.certificate}.p12"
  end

  return

  execute 'ipa-server-install' do
    command [
      'ipa-server-install',
      '--unattended',
      "--hostname=#{new_resource.server_hostname}",
      "--domain=#{new_resource.domain}",
      "--realm=#{new_resource.realm}",
      "--ds-password=#{new_resource.dirsrv_password}",
      "--admin-password=#{new_resource.admin_password}",
      '--no-pkinit',
      "--http-cert-file=/etc/pki/tls/certs/#{new_resource.certificate}.p12",
      "--http-pin=#{new_resource.certificate_pin}",
      "--dirsrv-cert-file=/etc/pki/tls/certs/#{new_resource.certificate}.p12",
      "--dirsrv-pin=#{new_resource.certificate_pin}",
      (new_resource.dns ? '--setup-dns' : nil),
      (new_resource.dns ? '--auto-forwarders' : nil),
      (new_resource.ntp ? nil : '--no-ntp'),
    ].compact.join(' ')
    sensitive true
    creates '/etc/ipa/default.conf'
    notifies :run, 'execute[ipactl restart]'
  end unless new_resource.replica

  execute 'ipactl restart' do
    action :nothing
  end

  %w(
    httpd
    ipa-custodia
    ipa-otpd.socket
    ipa
    kadmin
    krb5kdc
  ).each do |s|
    service s do
      action [:enable, :start]
    end
  end

  %w(
    named
    ipa-dnskeysyncd
  ).each do |s|
    service s do
      action [:enable, :start]
    end
  end if new_resource.dns
end
