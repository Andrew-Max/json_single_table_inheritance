require 'active_record/json_validator/validator'

module JsonSingleTableInheritance
  extend ActiveSupport::Concern

  included do
    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def self.define_schema(hash)
      class_eval do
        const_set(:SCHEMA, hash.with_indifferent_access)
        class_variable_set(:@@json_attrs, self::SCHEMA["properties"])
        class_variable_set(:@@json_required, self::SCHEMA["required"])
      end
    end

    def self.inherited(subclass)
      subclass.class_eval do
        # probably could do some more general validations
          #patch subclasses to validate based on their schema
          validates :module_data,
                    presence: false,
                    json: {
                      message: ->(errors) { errors },
                      schema: lambda { self.class::SCHEMA.to_json }
                    }
      end

      def method_missing(method_name, *args, &block)
        existing_attr = lookup_attr_method(method_name, args)
        if existing_attr
          return existing_attr == NilClass ? nil : existing_attr
        end

        existing_relationship = lookup_relationship_method(method_name)
        if existing_relationship
          return existing_relationship == NilClass ? nil : existing_relationship
        end

        super
      end

      def respond_to_missing?(method_name, *args)
        if self.class.class_variables.include? :@@json_attrs
          self.class.class_variable_get(:@@json_attrs).keys.include? method_name.to_s.gsub("=", "") or super
        end

        # using define method here will remove the entire necessity for this
        # this should be patched for the relationships case but not sure how
      end

      private

      def lookup_attr_method(method_name, args)
        # patch subclasses to check the attrs of it's module data on method missing
        # prefer to handle this with define_method
        if self.class.class_variable_get(:@@json_attrs).keys.include? method_name.to_s.gsub("=", "")
          if method_name.to_s.include? '='
            self.module_data[method_name.to_s.gsub("=", "")] = args.first

            return args.first.nil? ? NilClass : args.first
          else
            return self.module_data[method_name.to_s] || NilClass
          end
        end
      end

      def lookup_relationship_method(method_name)
        self_abstract, self_concrete = self.class.to_s.split("::").map(&:underscore)

        relationships = ClassMasterList.relations_lookup[self_abstract.to_sym][:relationships]

        #patch subclasses to allow AR helpers for querying other subtypes
        # prefer to handle this with define_method
        relationships.each do |relationship|
          if ClassMasterList.relations_lookup[relationship].present?
            if ClassMasterList.relations_lookup[relationship][:members].include?(method_name.to_s.singularize.to_sym)
              klass = "#{relationship.to_s.camelize}::#{method_name.to_s.singularize.camelize}".constantize

              relation = self.class.reflect_on_all_associations.detect do |relation|
                relation.class_name == relationship.to_s.camelize
              end

              relation_type = relation.to_s.split("::").last.split(':').first.gsub("Reflection", "").downcase
              method_str = method_name.to_s
              is_plural = method_str.pluralize == method_str

              # think about what happens here for always plural models
              if relation_type =~ /many/
                break unless is_plural
                return self.send(relationship.to_s.pluralize).where(type: klass.to_s)
              else
                break if is_plural

                rel = self.send(relationship.to_s)
                return rel.class.to_s == klass.to_s ? rel : NilClass
              end

            end
          end
        end
      end

      super
    end
  end
end