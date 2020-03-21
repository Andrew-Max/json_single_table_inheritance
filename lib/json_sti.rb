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
                      schema: lambda { self.class::SCHEMA }
                    }

          # handles bug in ransackable where 1 is converted to true
          def self.clean_val_aa(val)
            val.is_a?(TrueClass) ? 1 : val
          end

          # a helper similar to ARs `where` only for json fields
          scope :j_where, lambda { |hash| where("module_data @> ?", hash.to_json) }
          scope :j_like_key, lambda { |key, value| where("module_data ->> :key LIKE :value",key: key, value: "%#{value}%") }
          scope :j_gt, lambda { |prop, val|  where("module_data ->> '#{prop}' > ?", "#{clean_val_aa(val).to_f}") }
          scope :j_lt, lambda { |prop, val|  where("module_data ->> '#{prop}' < ?", "#{clean_val_aa(val).to_f}" ) }
          scope :j_gte, lambda { |prop, val|  where("module_data ->> '#{prop}' >= ?", "#{clean_val_aa(val).to_f}") }
          scope :j_lte, lambda { |prop, val|  where("module_data ->> '#{prop}' <= ?", "#{clean_val_aa(val).to_f}" ) }

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

        #creates methods required for ransackables searches in active admin
        class << self
          self.class_variable_get(:@@json_attrs).each do |prop, type|
            if type["type"].include?("string")
              define_method "#{prop}_equals" do |value|
                self.j_where(Hash[prop, value])
              end

              define_method "#{prop}_contains" do |value|
                self.j_like_key(prop, value)
              end
            elsif type["type"].include?("integer")
              define_method "#{prop}_equals" do |value|
                self.j_where(Hash[prop, value.to_i])
              end

              define_method "#{prop}_greater_than" do |value|
                self.j_gt(prop, value)
              end

              define_method "#{prop}_less_than" do |value|
                self.j_lt(prop, value)
              end
            elsif type["type"].include?("number")
              define_method "#{prop}_equals" do |value|
                self.j_where(Hash[prop, clean_val_aa(value).to_f])
              end

              define_method "#{prop}_greater_than" do |value|
                self.j_gt(prop, value)
              end

              define_method "#{prop}_less_than" do |value|
                self.j_lt(prop, value)
              end
            elsif type["type"].include?("boolean")
              # todo figure this out in for select, eq for checkboxes or viceversa
              # define_method "#{prop}_in" do |*value|
              #   self.j_where(Hash[prop, value])
              # end
            end
          end

          define_method "ransackable_scopes" do |_auth_object = nil|
            scopes = []

            ransackable_string_query_types = %i(equals contains)
            self.class_variable_get(:@@json_attrs).each do |prop, type|
              if type["type"].include?("string")
                ransackable_string_query_types.each do |ransackable_query_type|
                  scopes.push "#{prop}_#{ransackable_query_type}"
                end
              elsif type["type"].include?("integer")
                scopes.push "#{prop}_equals"
                scopes.push "#{prop}_greater_than"
                scopes.push "#{prop}_less_than"
              elsif type["type"].include?("number")
                scopes.push "#{prop}_equals"
                scopes.push "#{prop}_greater_than"
                scopes.push "#{prop}_less_than"
              elsif type["type"].include?("boolean")
                # todo figure this out in for select, eq for checkboxes or viceversa
                # scopes.push "#{prop}_in"
              end
            end

            scopes
          end
        end
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