require_relative '../../spec_helper'

describe 'test-idm::noggin' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge(step_into: %w(osl_noggin))).converge(described_recipe)
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to include_recipe 'osl-repos::epel' }
      it { is_expected.to accept_osl_firewall_port('http').with(ports: [8000]) }
      it { is_expected.to install_package 'noggin' }
      it { is_expected.to create_user('noggin').with(system: true, shell: '/usr/sbin/nologin') }
      it { is_expected.to create_directory('/etc/noggin').with(user: 'noggin', group: 'noggin') }
      it { is_expected.to create_directory('/var/log/noggin').with(user: 'noggin', group: 'noggin') }

      it do
        is_expected.to create_osl_systemd_unit_drop_in('bind').with(
          unit_name: 'noggin.service',
          content: <<~EOF
            [Service]
            ExecStart=
            ExecStart=sh -c "gunicorn-3 -u noggin -g noggin ${GUNICORN_OPTS} -w ${GUNICORN_WORKERS} --env NOGGIN_CONFIG_PATH=/etc/noggin/noggin.cfg --access-logfile /var/log/noggin/access.log --error-logfile /var/log/noggin/error.log --bind tcp://0.0.0.0:8000 'noggin.app:create_app()'"
          EOF
        )
      end

      it do
        is_expected.to create_template('/etc/sysconfig/noggin').with(
          user: 'noggin',
          group: 'noggin',
          cookbook: 'osl-idm',
          source: 'noggin-sysconfig.erb',
          variables: {
            gunicorn_opts: nil,
            gunicorn_workers: '3',
          }
        )
      end

      it { expect(chef_run.template('/etc/sysconfig/noggin')).to notify('service[noggin]').to(:restart) }

      it do
        is_expected.to create_template('/etc/noggin/noggin.cfg').with(
          user: 'noggin',
          group: 'noggin',
          cookbook: 'osl-idm',
          sensitive: true,
          mode: '0600',
          variables: {
            accept_images_from: [],
            activation_token_expiration: 30,
            allowed_username_human: ['a-z', '0-9', '-'],
            allowed_username_max_size: 32,
            allowed_username_min_size: 5,
            allowed_username_pattern: '^[a-z0-9][a-z0-9-]{3,30}[a-z0-9]$',
            avatar_default_type: 'robohash',
            avatar_service_url: 'https://seccdn.libravatar.org/',
            basset_url: nil,
            fernet_secret:  '-8Y6JVsS2a67PJ0ucTIAEVQT1KwgJcS5DWPnHp3GvgM=',
            freeipa_admin_password: 'admin_password',
            freeipa_admin_user: 'admin',
            freeipa_servers: %w(idm.testing.osuosl.org),
            mail_default_sender: 'Noggin <noggin@local>',
            mail_domain_blocklist: [],
            mail_suppress_send: false,
            page_size: 30,
            password_reset_expiration: 10,
            registration_open: true,
            secret_key: 'f9eef5765fa195857b94ba81f4c2855b72c24211401efc9949d1c742f385287d',
            spamcheck_token_expiration: 60,
            stage_users_role: 'Stage User Managers',
            templates_custom_directories: [],
            theme: 'default',
          }
        )
      end

      it { expect(chef_run.template('/etc/noggin/noggin.cfg')).to notify('service[noggin]').to(:restart) }
      it { is_expected.to enable_service 'noggin' }
      it { is_expected.to start_service 'noggin' }
    end
  end
end
