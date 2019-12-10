# frozen_string_literal: true
z = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift z

# require 'active_support/all'
require 'rspec'
# require 'mysql2'
require 'pg'

require 'pry-byebug'
require 'activerecord_json_validator'

# Require our macros and extensions
x = Dir[File.expand_path('../spec/support/macros/**/*.rb', __dir__)]
x.map(&method(:require))
y = Dir[File.expand_path('../spec/support/**/*.rb', __dir__)]
y.map(&method(:require))

binding.pry

RSpec.configure do |config|
  # Include our macros
  config.include DatabaseMacros
  config.include ModelMacros

  config.before :each do
    adapter = ENV['DB_ADAPTER'] || 'postgresql'
    setup_database(adapter: adapter, database: 'myapp_test_sti')
  end
end
