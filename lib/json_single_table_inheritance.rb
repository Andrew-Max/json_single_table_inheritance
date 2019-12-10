require 'json_single_table_inheritance/json_single_table_inheritance'
require 'json_single_table_inheritance/class_master_list'
require 'json_single_table_inheritance/inheritable_seeder'

require 'json-schema'
require 'active_record/json_validator/validator'

# NOTE: In case `"JSON"` is treated as an acronym by `ActiveSupport::Inflector`,
# make `JSONValidator` available too.
JSONValidator = JsonValidator