module JsonSingleTableInheritance
  class ClassMasterList
    def self.abstract_klasses
      @@abstract_klasses ||= ObjectSpace.
        each_object(Class).
        select { |klass| klass.included_modules.include? JsonSingleTableInheritance }.
        map(&:to_s).
        reject { |klass| klass.include?("::") }.
        map(&:underscore).
        map(&:to_sym)
    end

    def self.relations_lookup
      return @@relations_lookup ||= build_relations_lookup
    end

    def self.build_relations_lookup
      @@relations_lookup = {}

      abstract_klasses.each do |klass_name|
        @@relations_lookup[klass_name] = {}

        klass = klass_name
          .to_s
          .camelize
          .constantize

        associations = klass.reflect_on_all_associations

        relation_list = associations.map(&:class_name).
          map(&:to_s).
          map(&:underscore).
          map(&:to_sym)

        @@relations_lookup[klass_name][:relationships] = relation_list & abstract_klasses

        members = klass.descendants.map(&:to_s).
          map{ |descendant| descendant.gsub("#{klass_name.to_s.camelize}::", "") }.
          map(&:underscore).
          map(&:to_sym)

        @@relations_lookup[klass_name][:members] = members
      end

      @@relations_lookup
    end
  end
end