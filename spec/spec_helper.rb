require 'ruby-debug'
require 'rails'
require 'rspec'

$:.unshift File.dirname(__FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require "rails_app/config/environment"
require "rails/test_help"
require 'rspec/rails'
require 'sham_rack'

RSpec.configure do |config|
  config.mock_with :rspec
end

I18n.load_path << File.expand_path("../support/locale/en.yml", __FILE__)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

