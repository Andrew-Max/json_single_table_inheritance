lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json_single_table_inheritance/version'

Gem::Specification.new do |spec|
  spec.name        = 'json_single_table_inheritance'
  spec.version     =  JsonSingleTableInheritance::VERSION
  spec.date        = '2019-12-08'
  spec.summary     = "A scheme for single table inheritance with ActiveRecord which puts all class specific attributes in a json blob, and allows validations"
  spec.description = "A common argument against STI in rails is that the tables eventually get cluttered with class specific columns. By keeping all subtype specific attrs in json, you completely avoid table bloat while keeping all the advantages of AR and a relational database"
  spec.authors     = ["Andrew Max"]
  spec.email       = 'andrew.max89@gmail.com'
  spec.files       = ["lib/json_single_table_inheritance.rb"]
  spec.homepage    = nil
  spec.license       = 'MIT'

  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 0.8.7'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'pg', '~> 1.1'
  spec.add_development_dependency 'pry-byebug', '~> 3.7'
  spec.add_development_dependency 'faker', '~> 2.7'
  # spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'activesupport', '>= 4.2.0', '< 7'
  spec.add_development_dependency 'rubocop', '~> 0.77'
  spec.add_dependency 'activerecord', '>= 4.2.0', '< 7'

  spec.add_dependency 'activerecord_json_validator', '~> 1.3.0'
end