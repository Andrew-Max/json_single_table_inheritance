# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'pry-byebug'
require 'active_support/all'
require 'rspec'
# require 'mysql2'
require 'pg'
require 'faker'
require 'activerecord_json_validator'


# Require our macros and extensions
Dir[File.expand_path('../lib/**/*.rb', __dir__)].map(&method(:require))
Dir[File.expand_path('../spec/support/macros/**/*.rb', __dir__)].map(&method(:require))
Dir[File.expand_path('../spec/support/**/*.rb', __dir__)].map(&method(:require))

RSpec.configure do |config|
  # Include our macros
  config.include DatabaseMacros
  config.include ModelMacros

  config.before :each do
    adapter = ENV['DB_ADAPTER'] || 'postgresql'
    setup_database(adapter: adapter, database: 'myapp_test_sti')
  end
end
