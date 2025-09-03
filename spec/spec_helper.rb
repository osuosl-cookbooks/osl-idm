require 'chefspec'
require 'chefspec/berkshelf'

ALMA_9 = {
  platform: 'almalinux',
  version: '9',
}.freeze

ALL_PLATFORMS = [
  ALMA_9,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end
