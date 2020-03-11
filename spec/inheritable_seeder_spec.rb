require 'spec_helper'

describe JsonSti::InheritableSeeder do
  include_context "sti_setup_one"
  include_context "sti_setup_one_migrations"

  before do
    JsonSti.initialize_single_table_arel_helpers
  end

  describe 'populate_attrs_for_instance!' do

    let(:sub_a) { TypeOne::SubA.new }
    let(:sub_b) { TypeOne::SubB.new }
    let(:sub_c) { TypeTwo::SubC.new }
    let(:sub_d) { TypeThree::SubD.new }
    let(:sub_e) { TypeFour::SubE.new }

    describe "for required attrs" do
      it "sets the correct attributes on the object" do
        expect(sub_a.zebra).to     eq(nil)

        expect(sub_b.apple).to     eq(nil)
        expect(sub_b.brain).to     eq(nil)
        expect(sub_b.chamomile).to eq(nil)

        expect(sub_c.dog).to       eq(nil)
        expect(sub_c.emigrate).to  eq(nil)

        expect(sub_d.forest).to    eq(nil)
        expect(sub_d.great).to     eq(nil)

        expect(sub_e.hello).to     eq(nil)
        expect(sub_e.indigo).to    eq(nil)

        # to rescue from validations
        seeder = JsonSti::InheritableSeeder

        [sub_a, sub_b, sub_c, sub_d, sub_e].each do |obj|
          begin
            seeder.populate_attrs_for_instance!(obj, true)
          rescue
          end
        end

        expect(sub_a.zebra).to     be_in([true, false])

        expect(sub_b.apple).to     be_a(Float)
        expect(sub_b.brain).to     eq(nil)

        expect(sub_b.chamomile).to be_a(Date)

        expect(sub_c.dog).to       eq(nil)
        expect(sub_c.emigrate).to  be_a(String)

        expect(sub_d.forest).to    eq(nil)
        expect(sub_d.great).to     be_a(Integer)

        expect(sub_e.hello).to     be_a(Time)
        expect(sub_e.indigo).to    eq(nil)
      end
    end

    describe "for all attrs" do
      it "sets the correct attributes on the object" do
        expect(sub_a.zebra).to     eq(nil)

        expect(sub_b.apple).to     eq(nil)
        expect(sub_b.brain).to     eq(nil)
        expect(sub_b.chamomile).to eq(nil)

        expect(sub_c.dog).to       eq(nil)
        expect(sub_c.emigrate).to  eq(nil)

        expect(sub_d.forest).to    eq(nil)
        expect(sub_d.great).to     eq(nil)

        expect(sub_e.hello).to     eq(nil)
        expect(sub_e.indigo).to    eq(nil)

        # to rescue from validations
        seeder = JsonSti::InheritableSeeder

        [sub_a, sub_b, sub_c, sub_d, sub_e].each do |obj|
          begin
            seeder.populate_attrs_for_instance!(obj)
          rescue
          end
        end

        expect(sub_a.zebra).to     be_in([true, false])

        expect(sub_b.apple).to     be_a(Float)
        expect(sub_b.brain).to     be_a(String)

        expect(sub_b.chamomile).to be_a(String)
        parsed_date = Date.strptime(sub_b.chamomile, '%Y-%m-%d')
        expect(parsed_date).to be_a(Date)

        expect(sub_c.dog).to       be_a(Float)
        expect(sub_c.emigrate).to  be_a(String)

        expect(sub_d.forest).to    be_a(Float)
        expect(sub_d.great).to     be_a(Integer)

        expect(sub_e.hello).to     be_a(String)
        parsed_time = parsed_time = DateTime.strptime(sub_e.hello, '%Y-%m-%dT%H:%M:%S')

        expect(parsed_time).to     be_a(DateTime)
        expect(sub_e.indigo).to    be_a(String)
      end
    end
  end

  describe 'seed!' do
    it "creates valid seeds for every valid combination of subtypes" do
      expect(::TypeOne::SubA.count).to be_zero
      expect(::TypeOne::SubB.count).to be_zero
      expect(::TypeTwo::SubC.count).to be_zero
      expect(::TypeThree::SubD.count).to be_zero
      expect(::TypeFour::SubE.count).to be_zero

      expect { JsonSti::InheritableSeeder.seed! }.not_to raise_error

      expect(::TypeOne::SubA.count).to_not be_zero
      expect(::TypeOne::SubB.count).to_not be_zero
      expect(::TypeTwo::SubC.count).to_not be_zero
      expect(::TypeThree::SubD.count).to_not be_zero
      expect(::TypeFour::SubE.count).to_not be_zero
    end
  end
end