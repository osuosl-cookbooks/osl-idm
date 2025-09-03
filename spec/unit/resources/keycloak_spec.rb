require_relative '../../spec_helper'

describe 'test-idm::keycloak' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge(step_into: %w(osl_keycloak))).converge(described_recipe)
      end

      before do
        stub_command('iptables -C INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null').and_return(true)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to accept_osl_firewall_port('http').with(ports: [8080]) }
      it { is_expected.to include_recipe 'osl-docker' }
      it { is_expected.to_not install_osl_caddy 'keycloak' }
      it { is_expected.to_not create_osl_caddy_site 'keycloak.testing.osuosl.org' }
      it { is_expected.to pull_docker_image('quay.io/keycloak/keycloak').with(tag: '26.3') }

      it do
        expect(chef_run.docker_image('quay.io/keycloak/keycloak')).to \
           notify('docker_image[keycloak-keycloak.testing.osuosl.org]').to(:build)
      end

      it do
        is_expected.to create_directory('/opt/keycloak/keycloak.testing.osuosl.org').with(
          recursive: true
        )
      end

      it do
        is_expected.to create_template('/opt/keycloak/keycloak.testing.osuosl.org/Dockerfile').with(
          cookbook: 'osl-idm',
          sensitive: true,
          mode: '0600',
          variables: {
            db_engine: 'mariadb',
            db_url: 'jdbc:mariadb://10.0.0.2:3306/keycloak',
            db_user: 'keycloak',
            db_pass: 'keycloak',
            hostname: 'keycloak.testing.osuosl.org',
          }
        )
      end

      it do
        is_expected.to build_if_missing_docker_image('keycloak-keycloak.testing.osuosl.org').with(
          source: '/opt/keycloak/keycloak.testing.osuosl.org/Dockerfile'
        )
      end

      it do
        expect(chef_run.docker_image('keycloak-keycloak.testing.osuosl.org')).to \
          notify('docker_container[keycloak.testing.osuosl.org]').to(:redeploy)
      end

      it do
        is_expected.to run_docker_container('keycloak.testing.osuosl.org').with(
          repo: 'keycloak-keycloak.testing.osuosl.org',
          port: '8080:8080',
          restart_policy: 'always',
          sensitive: true,
          command: [
            'start',
            '--optimized',
            '--hostname=https://keycloak.testing.osuosl.org',
            '--http-enabled=true',
            '--proxy-headers',
            'xforwarded',
          ],
          env: [
            'KC_BOOTSTRAP_ADMIN_USERNAME=admin',
            'KC_BOOTSTRAP_ADMIN_PASSWORD=admin_password',
          ]
        )
      end
    end
  end
end
