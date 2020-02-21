module JsonSti
  class InheritableSeeder
    def self.seed!(num_to_create=3)
      relations_lookup = JsonSti::ClassMasterList.relations_lookup

      relations_lookup.each do |type, info|
        info[:members].each do |member|
          klass = "#{type.to_s.camelize}::#{member.to_s.camelize}".constantize
          instance = klass.create

          if !instance.valid?
            skip_sub_object_creation = self.fix_errors_on_instance_and_determine_next_step(instance)
            next if skip_sub_object_creation
          end

          p "Created a #{klass.to_s}"

          info[:relationships].each do |relationship|
            relations_lookup[relationship][:members].each do |relation_member|
              self.create_relationship_for_instance(instance, relationship, relation_member, num_to_create)
            end
          end
        end
      end
    end

    def self.populate_attrs_for_instance!(instance, only_required=false)
      klass = instance.class
      json_attrs = klass.class_variable_get(:@@json_attrs)
      return if json_attrs.blank?

      attrs = only_required ? klass.class_variable_get(:@@json_required) : klass.class_variable_get(:@@json_attrs).keys

      return if attrs.blank?

      attrs.each do |attr|
        type  = json_attrs[attr].values
        case type.first
          when "string"
            if type[1] && type[1] == "date"
              new_val = Faker::Date.between(from: 10.days.ago, to: Date.today)
            elsif type[1] && type[1] == "time"
              new_val = Faker::Time.between(from: DateTime.now - 1, to: DateTime.now)
            else
              new_val = Faker::Marketing.buzzwords
            end
          when "boolean"
            new_val = [true, false].sample
          when "integer"
            new_val = Integer(Faker::Number.within(range: 0..99))
          when "number"
            new_val = Faker::Number.decimal(l_digits:2, r_digits: 3)
        end

        instance.send((attr.to_s + "="), new_val)
      end

      instance.save!

      instance
    end

    def self.generate_valid_instance_of_class!(klass, only_required=false)
      populate_attrs_for_instance!(klass.new, only_required)
    end

    private

    def self.create_relationship_for_instance(instance, relationship_type, relation_member, num_to_create)
      p "Creating a #{relation_member} for a #{instance.class}"

      num_to_create.times do |n|
        ar_association = instance.class.reflect_on_all_associations.detect do |association|
          association.class_name == relationship_type.to_s.camelize
        end

        if ar_association.to_s.downcase =~ /many/
          relation_name = relation_member.to_s.pluralize
          sub_instance = instance.send(relation_name).create
        else
          klass_to_create = "#{relationship_type.to_s.camelize}::#{relation_member.to_s.camelize}".constantize
          sub_instance = generate_valid_instance_of_class!(klass_to_create)

          sub_instance_rel_id = sub_instance.class.to_s.split("::").first.underscore + "_id="
          instance.send(sub_instance_rel_id, sub_instance.id)
        end

        JsonSti::InheritableSeeder.populate_attrs_for_instance!(sub_instance)
      end
    end

    def self.fix_errors_on_instance_and_determine_next_step(instance)
      klass = instance.class
      skip_sub_object_creation = false

      instance.errors.messages.each do |error_key, error_value|
        if error_key == :module_data
          JsonSti::InheritableSeeder.populate_attrs_for_instance!(instance)

        elsif error_value.include? "must exist"
          fix_belongs_to_based_errors_for_instance(instance, error_key)
          skip_sub_object_creation = true

        else
          p "============================="
          p "There was an unhandled error on instance creation: #{error_key} : #{error_value.first}"
          p "============================="
          skip_sub_object_creation = true
        end
      end

      skip_sub_object_creation
    end

    def self.fix_belongs_to_based_errors_for_instance(instance, error_key)
      valid_sub_type = ClassMasterList.relations_lookup[error_key][:members].sample.to_s
      sub_type_klass = "#{error_key.to_s.camelize}::#{valid_sub_type.camelize}".constantize

      p "creating #{sub_type_klass.to_s} belongs to for #{instance.class.to_s}"
      new_sub_instance = instance.send("#{error_key}=", sub_type_klass.create)

      JsonSti::InheritableSeeder.populate_attrs_for_instance!(new_sub_instance)
    end
  end
end