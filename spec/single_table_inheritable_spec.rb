require 'spec_helper'

describe JsonSingleTableInheritance do
  include_context "sti_setup_one"
  include_context "sti_setup_one_migrations"

  describe 'A class which includes the module' do
    before do
      JsonSingleTableInheritance.initialize_single_table_arel_helpers
    end

    let(:sub_a) { TypeOne::SubA.new }
    let(:sub_b) { TypeOne::SubB.new }
    let(:sub_c) { TypeTwo::SubC.new }
    let(:sub_d) { TypeThree::SubD.new }
    let(:sub_e) { TypeFour::SubE.new }

    it "has constants for its sub classes" do
      expect(defined? SubA).to_not be nil
      expect(defined? SubB).to_not be nil
      expect(defined? SubC).to_not be nil
      expect(defined? SubD).to_not be nil
      expect(defined? SubE).to_not be nil

      expect(defined? SubZ).to be nil
    end

    it "has been patched with getter methods for it's module_data attrs" do
      expect(sub_a).to respond_to("zebra")
      expect(sub_a).to_not respond_to("apple")
      expect(sub_a).to_not respond_to("brain")
      expect(sub_a).to_not respond_to("chamomile")
      expect(sub_a).to_not respond_to("dog")
      expect(sub_a).to_not respond_to("emigrate")
      expect(sub_a).to_not respond_to("forest")
      expect(sub_a).to_not respond_to("great")
      expect(sub_a).to_not respond_to("hello")

      expect(sub_b).to respond_to("apple")
      expect(sub_b).to respond_to("brain")
      expect(sub_b).to respond_to("chamomile")
      expect(sub_b).to_not respond_to("emigrate")

      expect(sub_c).to respond_to("dog")
      expect(sub_c).to respond_to("emigrate")
      expect(sub_c).to_not respond_to("great")

      expect(sub_d).to respond_to("forest")
      expect(sub_d).to respond_to("great")
      expect(sub_d).to_not respond_to("dog")

      expect(sub_e).to respond_to("hello")
      expect(sub_e).to respond_to("indigo")
      expect(sub_a).to_not respond_to("forest")
    end

    it "has been patched with setter methods for it's module_data attrs" do
      expect(sub_a).to respond_to("zebra=")
      expect(sub_a).to_not respond_to("apple=")
      expect(sub_a).to_not respond_to("brain=")
      expect(sub_a).to_not respond_to("chamomile=")
      expect(sub_a).to_not respond_to("dog=")
      expect(sub_a).to_not respond_to("emigrate=")
      expect(sub_a).to_not respond_to("forest=")
      expect(sub_a).to_not respond_to("great=")
      expect(sub_a).to_not respond_to("hello=")

      expect(sub_b).to respond_to("apple=")
      expect(sub_b).to respond_to("brain=")
      expect(sub_b).to respond_to("chamomile=")
      expect(sub_b).to_not respond_to("emigrate=")

      expect(sub_c).to respond_to("dog=")
      expect(sub_c).to respond_to("emigrate=")
      expect(sub_c).to_not respond_to("great=")

      expect(sub_d).to respond_to("forest=")
      expect(sub_d).to respond_to("great=")
      expect(sub_d).to_not respond_to("dog=")

      expect(sub_e).to respond_to("hello=")
      expect(sub_e).to respond_to("indigo=")
      expect(sub_a).to_not respond_to("forest=")
    end

    it "has been patched with ar like has_many helper methods for the sub types of the classes it has relationships with" do
      expect(sub_a).to_not respond_to("sub_as")
      expect(sub_a).to_not respond_to("sub_bs")
      expect(sub_a).to respond_to("sub_cs")
      expect(sub_a).to respond_to("sub_ds")
      expect(sub_a).to respond_to("sub_es")

      expect(sub_b).to_not respond_to("sub_as")
      expect(sub_b).to_not respond_to("sub_bs")
      expect(sub_b).to respond_to("sub_cs")
      expect(sub_b).to respond_to("sub_ds")
      expect(sub_b).to respond_to("sub_es")

      expect(sub_c).to respond_to("sub_as")
      expect(sub_c).to respond_to("sub_bs")
      expect(sub_c).to_not respond_to("sub_cs")
      expect(sub_c).to_not respond_to("sub_ds")
      expect(sub_c).to respond_to("sub_es")

      expect(sub_d).to_not respond_to("sub_as")
      expect(sub_d).to_not respond_to("sub_bs")
      expect(sub_d).to_not respond_to("sub_cs")
      expect(sub_d).to_not respond_to("sub_ds")
      expect(sub_d).to_not respond_to("sub_es")

      expect(sub_e).to respond_to("sub_as")
      expect(sub_e).to respond_to("sub_bs")
      expect(sub_e).to respond_to("sub_cs")
      expect(sub_e).to_not respond_to("sub_ds")
      expect(sub_e).to_not respond_to("sub_es")
    end

    it "has been patched with ar like belongs helper methods for the sub types of the classes it has relationships with" do
      expect(sub_a).to_not respond_to("sub_a")
      expect(sub_a).to_not respond_to("sub_b")
      expect(sub_a).to_not respond_to("sub_c")
      expect(sub_a).to_not respond_to("sub_d")
      expect(sub_a).to_not respond_to("sub_e")

      expect(sub_b).to_not respond_to("sub_a")
      expect(sub_b).to_not respond_to("sub_b")
      expect(sub_b).to_not respond_to("sub_c")
      expect(sub_b).to_not respond_to("sub_d")
      expect(sub_b).to_not respond_to("sub_e")

      expect(sub_c).to_not respond_to("sub_a")
      expect(sub_c).to_not respond_to("sub_b")
      expect(sub_c).to_not respond_to("sub_c")
      expect(sub_c).to_not respond_to("sub_d")
      expect(sub_c).to_not respond_to("sub_e")

      expect(sub_d).to     respond_to("sub_a")
      expect(sub_d).to     respond_to("sub_b")
      expect(sub_d).to_not respond_to("sub_c")
      expect(sub_d).to_not respond_to("sub_d")
      expect(sub_d).to_not respond_to("sub_e")

      expect(sub_e).to_not respond_to("sub_a")
      expect(sub_e).to_not respond_to("sub_b")
      expect(sub_e).to_not respond_to("sub_c")
      expect(sub_e).to_not respond_to("sub_d")
      expect(sub_e).to_not respond_to("sub_e")
    end
  end
end
