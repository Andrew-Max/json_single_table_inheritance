RSpec.shared_context "sti_setup_one", :shared_context => :metadata do
  class ::TypeOne < ActiveRecord::Base
    include JsonSingleTableInheritance
    has_and_belongs_to_many :type_twos
    has_many :type_threes
    has_and_belongs_to_many :type_fours
    has_and_belongs_to_many :non_stis
  end

  class ::TypeTwo < ActiveRecord::Base
    include JsonSingleTableInheritance
    has_and_belongs_to_many :type_ones
    has_and_belongs_to_many :type_fours
  end

  class ::TypeThree < ActiveRecord::Base
    include JsonSingleTableInheritance
    belongs_to :type_one
  end

  class ::TypeFour < ActiveRecord::Base
    include JsonSingleTableInheritance
    has_and_belongs_to_many :type_twos
    has_and_belongs_to_many :type_ones
  end

  class NonSti < ActiveRecord::Base
    has_and_belongs_to_many :type_ones
  end

  class ::TypeOne::SubA < ::TypeOne
    define_schema({
      type: "object",
      properties: {
        zebra:             { type: "boolean" },
      },
      required: [:zebra]
    })
  end

  class ::TypeOne::SubB < ::TypeOne
    define_schema({
      type: "object",
      properties: {
        apple:             { type: "number", format: "decimal" },
        brain:             { type: "string" },
        chamomile:         { type: "string", format: "date" },
      },
      required: [:apple, :chamomile]
    })
  end

  class ::TypeTwo::SubC < ::TypeTwo
    define_schema({
      type: "object",
      properties: {
        dog:         { type: "number", format: "decimal" },
        emigrate:    { type: "string" },
      },
      required: [:emigrate]
    })
  end

  class ::TypeThree::SubD < ::TypeThree
    define_schema({
      type: "object",
      properties: {
        forest: { type: "number", format: "decimal" },
        great:  { type: "integer" },
      },
      required: [:great]
    })
  end

  class ::TypeFour::SubE < ::TypeFour
    define_schema({
      type: "object",
      properties: {
        hello:  { type: "string", format: "time" },
        indigo: { type: "string" },
      },
      required: [:hello]
    })
  end
end

RSpec.shared_context "sti_setup_one_migrations", :shared_context => :metadata do
  before do
    run_migration do
      create_table :type_ones do |t|
        t.string   :type, null: false
        t.jsonb    :module_data, default: {}
      end

      create_table :type_twos do |t|
        t.string   :type, null: false
        t.jsonb    :module_data, default: {}
      end

      create_table :type_threes do |t|
        t.string   :type, null: false
        t.jsonb    :module_data, default: {}
        t.integer  :type_one_id
      end

      create_table :type_fours do |t|
        t.string   :type, null: false
        t.jsonb    :module_data, default: {}
      end

      create_join_table :type_ones, :type_twos
      create_join_table :type_ones, :type_fours
      create_join_table :type_fours, :type_twos
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context "sti_setup_one", :include_shared => true
  rspec.include_context "sti_setup_one_migrations", :include_shared => true
end