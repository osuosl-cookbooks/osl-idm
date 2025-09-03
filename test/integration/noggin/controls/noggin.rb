control 'noggin' do
  describe package 'noggin' do
    it { should be_installed }
  end

  describe user 'noggin' do
    it { should exist }
    its('group') { should eq 'noggin' }
    its('shell') { should eq '/usr/sbin/nologin' }
  end

  describe group 'noggin' do
    it { should exist }
  end

  describe directory '/etc/noggin' do
    it { should exist }
    its('owner') { should eq 'noggin' }
    its('group') { should eq 'noggin' }
    its('mode') { should cmp '0755' }
  end

  describe directory '/var/log/noggin' do
    it { should exist }
    its('owner') { should eq 'noggin' }
    its('group') { should eq 'noggin' }
    its('mode') { should cmp '0755' }
  end

  describe file '/etc/noggin/noggin.cfg' do
    its('owner') { should eq 'noggin' }
    its('group') { should eq 'noggin' }
    it { should_not be_readable.by('others') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable.by('others') }
    its('mode') { should cmp '0600' }
    its('content') { should match /^ACCEPT_IMAGES_FROM = \[\]$/ }
    its('content') { should match /^ACTIVATION_TOKEN_EXPIRATION = 30$/ }
    its('content') { should match /^ALLOWED_USERNAME_HUMAN = \["a-z", "0-9", "-"\]$/ }
    its('content') { should match /^ALLOWED_USERNAME_MAX_SIZE = 32$/ }
    its('content') { should match /^ALLOWED_USERNAME_MIN_SIZE = 5$/ }
    its('content') { should match /^ALLOWED_USERNAME_PATTERN = "\^\[a-z0-9\]\[a-z0-9-\]\{3,30\}\[a-z0-9\]\$"$/ }
    its('content') { should match /^AVATAR_DEFAULT_TYPE = "robohash"$/ }
    its('content') { should match /^BASSET_URL = None$/ }
    its('content') { should match /^FERNET_SECRET = b'-8Y6JVsS2a67PJ0ucTIAEVQT1KwgJcS5DWPnHp3GvgM='$/ }
    its('content') { should match /^FREEIPA_ADMIN_PASSWORD = 'admin_password'$/ }
    its('content') { should match /^FREEIPA_ADMIN_USER = 'admin'$/ }
    its('content') { should match /^FREEIPA_SERVERS = \["idm.testing.osuosl.org"\]$/ }
    its('content') { should match /^MAIL_DEFAULT_SENDER = "Noggin <noggin@novalocal>"$/ }
    its('content') { should match /^MAIL_DOMAIN_BLOCKLIST = \[\]$/ }
    its('content') { should match /^MAIL_SUPPRESS_SEND = True$/ }
    its('content') { should match /^PAGE_SIZE = 30$/ }
    its('content') { should match /^PASSWORD_RESET_EXPIRATION = 10$/ }
    its('content') { should match %r{^AVATAR_SERVICE_URL = "https://seccdn.libravatar.org/"$} }
    its('content') { should match /^REGISTRATION_OPEN = True$/ }
    its('content') { should match /^SECRET_KEY = b'f9eef5765fa195857b94ba81f4c2855b72c24211401efc9949d1c742f385287d'$/ }
    its('content') { should match /^SPAMCHECK_TOKEN_EXPIRATION = 60$/ }
    its('content') { should match /^TEMPLATES_CUSTOM_DIRECTORIES = \[\]$/ }
    its('content') { should match /^THEME = "default"$/ }
  end

  describe file '/etc/sysconfig/noggin' do
    it { should be_file }
    its('owner') { should eq 'noggin' }
    its('group') { should eq 'noggin' }
    its('content') { should match /^GUNICORN_WORKERS="3"$/ }
    its('content') { should match /^GUNICORN_OPTS=""$/ }
  end

  describe systemd_service 'noggin' do
    its('params.ExecStart') { should cmp "{ path=sh ; argv[]=sh -c gunicorn-3 -u noggin -g noggin ${GUNICORN_OPTS} -w ${GUNICORN_WORKERS} --env NOGGIN_CONFIG_PATH=/etc/noggin/noggin.cfg --access-logfile /var/log/noggin/access.log --error-logfile /var/log/noggin/error.log --bind tcp://0.0.0.0:8000 'noggin.app:create_app()' ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }" }
  end

  describe service 'noggin' do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe port 8000 do
    it { should be_listening }
    its('protocols') { should include 'tcp' }
    its('addresses') { should include '0.0.0.0' }
  end

  describe http('http://localhost:8000/') do
    its('status') { should cmp 200 }
    its('body') { should match '<title>noggin</title>' }
    its('body') { should match /Login/ }
  end
end
