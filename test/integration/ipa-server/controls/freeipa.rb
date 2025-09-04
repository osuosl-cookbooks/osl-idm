control 'freeipa' do
  %w(
    ipa-server
    ipa-healthcheck
    ipa-server-dns
  ).each do |p|
    describe package p do
      it { should be_installed }
    end
  end

  describe file '/etc/pki/tls/certs/wildcard.p12' do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file('/etc/ipa/default.conf') do
    it { should be_file }
    its('content') { should match /basedn = dc=testing,dc=osuosl,dc=org/ }
    its('content') { should match /realm = TESTING.OSUOSL.ORG/ }
    its('content') { should match /domain = testing.osuosl.org/ }
    its('content') { should match /host = idm.testing.osuosl.org/ }
  end

  %w(
    dirsrv@TESTING-OSUOSL-ORG.service
    httpd.service
    ipa-custodia.service
    ipa-otpd.socket
    ipa.service
    kadmin.service
    krb5kdc.service
    named.service
    ipa-dnskeysyncd.service
  ).each do |s|
    describe service s do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end
  end

  %w(
    80
    443
    389
    636
    88
    464
  ).each do |p|
    describe port p do
      it { should be_listening }
      its('protocols') { should include 'tcp' }
    end
  end

  describe port 53 do
    it { should be_listening }
    its('protocols') { should include('tcp') }
    its('protocols') { should include('udp') }
  end

  describe command 'dig @localhost idm.testing.osuosl.org A +short' do
    its('exit_status') { should eq 0 }
    # This regex matches an IPv4 address
    its('stdout') { should match /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\n?$/ }
    its('stderr') { should be_empty }
  end

  describe service 'chronyd' do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe port 123 do
    it { should be_listening }
    its('protocols') { should include('udp') }
  end

  describe command 'chronyc activity' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /200 OK/ }
    its('stdout') { should match /\d+ sources online/ } # Checks that it's tracking sources
  end

  describe command 'echo "admin_password" | kinit admin && ipa user-find admin' do
    its('stdout') { should match /User login: admin/ }
    its('exit_status') { should eq 0 }
  end

  describe command 'ipactl status' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /Directory Service: RUNNING/ }
    its('stdout') { should match /krb5kdc Service: RUNNING/ }
    its('stdout') { should match /kadmin Service: RUNNING/ }
    its('stdout') { should match /httpd Service: RUNNING/ }
    its('stdout') { should match /named Service: RUNNING/ }
    its('stdout') { should match /ipa-custodia Service: RUNNING/ }
    its('stdout') { should match /ipa-otpd Service: RUNNING/ }
    its('stdout') { should match /ipa-dnskeysyncd Service: RUNNING/ }
    its('stderr') { should match /ipa: INFO: The ipactl command was successful/ }
  end

  describe http('https://idm.testing.osuosl.org/ipa/ui/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('body') { should match %r{<title>Identity Management</title>} }
  end

  describe command 'ipa-healthcheck --failures-only' do
    its('stdout') { should eq "[]\n" }
    its('exit_status') { should eq 0 }
  end
end
