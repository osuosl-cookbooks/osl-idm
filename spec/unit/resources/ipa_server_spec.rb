require_relative '../../spec_helper'

describe 'test-idm::ipa_server' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge(step_into: %w(osl_ipa_server))).converge(described_recipe)
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to accept_osl_firewall_port 'http' }
      it { is_expected.to accept_osl_firewall_port 'ldap' }
      it { is_expected.to accept_osl_firewall_kerberos 'ipa_server' }
      it { is_expected.to accept_osl_firewall_dns 'ipa_server' }
      it { is_expected.to install_package %w(ipa-server ipa-healthcheck) }
      it { is_expected.to install_package 'ipa-server-dns' }

      it do
        is_expected.to create_certificate_manage('wildcard').with(
          cert_file: 'wildcard.crt',
          key_file: 'wildcard.key',
          chain_file: 'wildcard.ca-bundle'
        )
      end

      it do
        expect(chef_run.certificate_manage('wildcard')).to \
          notify('execute[create openssl pkcs12 wildcard.p12]').to(:run).immediately
      end

      it do
        is_expected.to run_execute('create openssl pkcs12 wildcard.p12').with(
          sensitive: true,
          creates: '/etc/pki/tls/certs/wildcard.p12',
          command: "openssl pkcs12 -export -name 'httpd-ds-cert' -passout \"pass:1234\" -certfile /etc/pki/tls/certs/wildcard.ca-bundle -inkey /etc/pki/tls/private/wildcard.key -in /etc/pki/tls/certs/wildcard.crt -out /etc/pki/tls/certs/wildcard.p12"
        )
      end

      it do
        is_expected.to run_execute('ipa-server-install').with(
          command: 'ipa-server-install --unattended --hostname=idm.testing.osuosl.org --domain=testing.osuosl.org --realm=TESTING.OSUOSL.ORG --ds-password=dirsrv_password --admin-password=admin_password --no-pkinit --http-cert-file=/etc/pki/tls/certs/wildcard.p12 --http-pin=1234 --dirsrv-cert-file=/etc/pki/tls/certs/wildcard.p12 --dirsrv-pin=1234 --setup-dns --auto-forwarders',
          sensitive: true,
          creates: '/etc/ipa/default.conf'
        )
      end

      it { expect(chef_run.execute('ipa-server-install')).to notify('execute[ipactl restart]').to(:run) }
      it { is_expected.to nothing_execute 'ipactl restart' }

      %w(
        httpd
        ipa-custodia
        ipa-otpd.socket
        ipa
        kadmin
        krb5kdc
        named
        ipa-dnskeysyncd
      ).each do |s|
        it { is_expected.to enable_service s }
        it { is_expected.to start_service s }
      end
    end
  end
end
