module JsonSingleTableInheritance
  class InheritableSeeder
    def self.seed!
      relations_lookup = JsonSingleTableInheritance::ClassMasterList.relations_lookup

      relations_lookup.each do |type, info|
        info[:members].each do |member|
          klass = "#{type.to_s.camelize}::#{member.to_s.camelize}".constantize
          instance = klass.create

          top_level_next = false

          unless instance.valid?
            instance.errors.messages.each do |error_key, error_value|
              if error_key == :module_data
                JsonSingleTableInheritance::InheritableSeeder.populate_attrs_for_instance!(klass, instance)
                instance.save!

              elsif error_value.include? "must exist"
                valid_sub_type = ClassMasterList.relations_lookup[error_key][:members].sample.to_s
                sub_type_klass = "#{error_key.to_s.camelize}::#{valid_sub_type.camelize}".constantize

                p "creating #{sub_type_klass.to_s} belongs to for #{instance.class.to_s}"
                new_sub_instance = instance.send("#{error_key}=", sub_type_klass.create)

                # JsonSingleTableInheritance::InheritableSeeder.populate_attrs_for_instance!(new_sub_instance.class, new_sub_instance)
                top_level_next = true
              else
                top_level_next = true
              end
            end
          end

          next if top_level_next

          p "Created a #{klass.to_s}"

          associations = klass.reflect_on_all_associations

          info[:relationships].each do |relationship|
            relations_lookup[relationship][:members].each do |relation_member|
              p "Created a #{relationship} for a #{klass.to_s}"
              3.times do |n|
                begin
                  sub_instance = instance.send(relation_member).create
                  JsonSingleTableInheritance::InheritableSeeder.populate_attrs_for_instance!(sub_instance.class, sub_instance)
                rescue
                  begin
                    sub_instance = instance.send(relation_member.to_s.pluralize).try(:create)
                    JsonSingleTableInheritance::InheritableSeeder.populate_attrs_for_instance!(sub_instance.class, sub_instance)
                  rescue => e
                    p '======================'
                    p e
                    p '======================'
                  end
                end
              end
            end
          end
        end
      end
    end

    def self.populate_attrs_for_instance!(klass, instance, only_required=false)
      json_attrs = klass.class_variable_get(:@@json_attrs)
      return if json_attrs.blank?

      if only_required
        attrs = klass.class_variable_get(:@@json_required)
      else
        attrs = klass.class_variable_get(:@@json_attrs).keys
      end

      return if attrs.blank?

      attrs.each do |attr|
        meth = attr.to_s + "="
        type = json_attrs[attr].values.first

        if type == "string"
          new_val = Faker::Marketing.buzzwords
        elsif type == "boolean"
          new_val = [true, false].sample
        elsif type == "integer"
          new_val = Integer(Faker::Number.within(range: 0..99))
        elsif type == "decimal"
          new_val = Faker::Number.decimal(l_digits:2, r_digits: 3)
        elsif type == "date"
          new_val = Faker::Date.between(from: 10.days.ago, to: Date.today)
        elsif type == "time"
          new_val = Faker::Time.between(from: DateTime.now - 1, to: DateTime.now)
        end

        instance.send(meth, new_val)
      end

      instance.save!
    end
  end
end