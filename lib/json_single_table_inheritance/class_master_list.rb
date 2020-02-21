module JsonSingleTableInheritance
  class ClassMasterList
    def self.sti_base_class_list
      # a list of STI base classes which have their own tables
      @@sti_base_class_list ||= build_sti_base_class_list
    end

    def self.relations_lookup
      # a lookup table including the subclasses of each baseclasses
      # and what relationships each STI class has to other STI classes
      @@relations_lookup ||= build_relations_lookup
    end

    def self.base_class_list
      # a list of STI base classes which have their own tables
      @@base_class_list ||= build_base_class_list
    end

    private

    def self.build_sti_base_class_list
      ObjectSpace.
        each_object(Class).
        select { |klass| klass.included_modules.include? JsonSingleTableInheritance }.
        map(&:to_s).
        reject { |klass| klass.include?("::") }.
        map(&:underscore).
        map(&:to_sym)
    end

    def self.build_base_class_list
      models = ActiveRecord::Base.
        descendants.
        map(&:name).
        reject { |klass| klass.include?("::") }.
        reject { |klass| klass.include?("HABTM") }.
        reject { |klass| klass.include?("WP") }.
        map(&:underscore).
        map(&:to_sym).
        tap { |models| models.delete :application_record}
    end

    def self.build_relations_lookup
      @@relations_lookup = {}

      base_class_list.each do |class_name|
        @@relations_lookup[class_name] = {}
        build_relation_list_for_class(class_name)
        build_members_list_for_class(class_name)
      end

      @@relations_lookup
    end

    def self.build_relation_list_for_class(class_name)
        klass = class_name.to_s.camelize.constantize
        associations = klass.reflect_on_all_associations

        relation_list = associations.map(&:class_name).
          map(&:to_s).
          map(&:underscore).
          map(&:to_sym)

        @@relations_lookup[class_name][:relationships] = (relation_list & JsonSingleTableInheritance::ClassMasterList.sti_base_class_list)
    end

    def self.build_members_list_for_class(class_name)
        klass = class_name.to_s.camelize.constantize
        members = klass.descendants.map(&:to_s).
          map{ |descendant| descendant.gsub("#{class_name.to_s.camelize}::", "") }.
          map(&:underscore).
          map(&:to_sym)

        @@relations_lookup[class_name][:members] = members
    end
  end
end