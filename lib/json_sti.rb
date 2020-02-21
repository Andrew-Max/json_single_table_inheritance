require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

require_relative "json_sti/class_master_list"
require_relative "json_sti/inheritable_seeder"

module JsonSti
  extend ActiveSupport::Concern

  def self.initialize_single_table_arel_helpers
    JsonSti::ClassMasterList.base_class_list.each do |receiving_class_name|
      receiving_class = receiving_class_name.to_s.camelize.constantize

      next unless ClassMasterList.relations_lookup[receiving_class_name]

      ClassMasterList.relations_lookup[receiving_class_name][:relationships].each do |relationship_to_create|
        ClassMasterList.relations_lookup[relationship_to_create][:members].each do |relationship_to_create_member|
          creation_class = "#{relationship_to_create.to_s.camelize}::#{relationship_to_create_member.to_s.singularize.camelize}".constantize

          ar_association = receiving_class.reflect_on_all_associations.detect do |association|
            association.class_name == relationship_to_create.to_s.camelize
          end

          receiving_class.class_eval do
            if ar_association.to_s.downcase =~ /many/
              # create has_many helper methods for sti subtypes
              define_method "#{relationship_to_create_member.to_s.pluralize}" do
                self.send(relationship_to_create.to_s.pluralize).where(type: creation_class.to_s)
              end

            else
              # create belongs_to helper methods for sti subtypes
              define_method "#{relationship_to_create_member.to_s.singularize}" do
                object = self.send(relationship_to_create.to_s.singularize)
                return object.class.to_s == creation_class.to_s ? object : nil
              end
            end
          end
        end
      end
    end
  end

  included do
    def self.inherited(subclass)
      begin
        #check to make sure if it exists, throws error and rescues with constant creation otherwise
        subclass.to_s.split("::").last.constantize
      rescue
        # define subclass name as constant on global object
        # probably smarter way to do this? Something zeitwerk?
        Object.const_set(subclass.to_s.split("::").last, subclass)

        subclass.class_eval do
          # patch subclasses to validate based on their schema.
          # Schemas are defined in subclasses with `define_schema`
          validates :module_data,
                    presence: false,
                    json: {
                      message: ->(errors) { errors },
                      schema: lambda { cleaned_schema }
                    }

          # a helper similar to ARs `where` only for json fields
          scope :jwhere, lambda { |hash| where("module_data @> ?", hash.to_json) }

          def initialize(params)
            super

            self.class::SCHEMA["properties"].keys.each do |attr|
              unless self.module_data[attr]
                if self.class::SCHEMA["required"].include? attr
                  self.module_data[attr] = "REQUIRED: #{self.class::SCHEMA["properties"][attr]["type"]}"
                else
                  self.module_data[attr] = nil
                end
              end
            end
          end

          private

          def cleaned_schema
            schema = self.class::SCHEMA.to_json

            hash_schema = JSON.parse(schema)
            properties = hash_schema["properties"]
            required = schema['required']

            properties.each do |property, value|
              unless self.module_data[property]
                unless required.include?(property)
                  properties.delete property
                end
              end
            end

            hash_schema["properties"] = properties
            hash_schema.to_json
          end
        end
      end

      super
    end

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def self.define_schema(hash)
      class_eval do
        const_set(:SCHEMA, hash.with_indifferent_access)

        json_attrs = self::SCHEMA["properties"]

        class_variable_set(:@@json_attrs, self::SCHEMA["properties"])
        class_variable_set(:@@json_required, self::SCHEMA["required"])

        initialize_attr_getters(json_attrs.keys)
        initialize_attr_setters(json_attrs.keys)
      end
    end

    private

    def self.initialize_attr_getters(attr_names)
      # patches including classes to have getters for their json attr names
      attr_names.each do |attr_name|
        define_method attr_name do
          self.module_data[attr_name]
        end
      end
    end

    def self.initialize_attr_setters(attr_names)
      # patches including classes to have setters for their json attr names
      attr_names.each do |attr_name|
        define_method "#{attr_name}=" do |new_value|
          self.module_data[attr_name] = new_value
        end
      end
    end
  end

end

loader.eager_load