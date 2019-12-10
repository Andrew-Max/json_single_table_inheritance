lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json_single_table_inheritance/version'

Gem::Specification.new do |spec|
  spec.name        = 'json_single_table_inheritance'
  spec.version     =  JsonSingleTableInheritance::VERSION
  spec.date        = '2019-12-08'
  spec.summary     = "A scheme for single table inheritance which puts all class specific attributes in a json blob, including validations"
  spec.description = "A scheme for single table inheritance which puts all class specific attributes in a json blob, including validations"
  spec.authors     = ["Andrew Max"]
  spec.email       = 'andrew.max89@gmail.com'
  spec.files       = ["lib/json_single_table_inheritance.rb"]
  spec.homepage    = nil
  spec.license       = 'AGPL-3.0-or-later'

  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'pry-byebug'
  # spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'activesupport', '>= 4.2.0', '< 7'
  spec.add_development_dependency 'rubocop', '~> 0.28'
  spec.add_dependency 'activerecord', '>= 4.2.0', '< 7'

  spec.add_dependency 'activerecord_json_validator', '~> 1.3.0'
end