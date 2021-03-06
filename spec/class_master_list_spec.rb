require 'spec_helper'

describe JsonSti::ClassMasterList do
  include_context "sti_setup_one"

  describe 'build_sti_base_class_list' do
    it "creates an accurate list of present abstract sti classes" do
      class_list = JsonSti::ClassMasterList.sti_base_class_list
      expect(class_list).to contain_exactly(:type_one, :type_two, :type_three, :type_four)
    end
  end

  describe 'build_relations_lookup' do
    it "creates an accurate map of the sti classes in the app and their members and relationships" do
      relation_map = JsonSti::ClassMasterList.relations_lookup

      expect(relation_map.keys).to eq(JsonSti::ClassMasterList.base_class_list)

      expect(relation_map[:type_one][:relationships]).to contain_exactly(:type_two, :type_three, :type_four)
      expect(relation_map[:type_one][:members]).to contain_exactly(:sub_a, :sub_b)

      expect(relation_map[:type_two][:relationships]).to contain_exactly(:type_one, :type_four)
      expect(relation_map[:type_two][:members]).to contain_exactly(:sub_c)

      expect(relation_map[:type_three][:relationships]).to contain_exactly(:type_one)
      expect(relation_map[:type_three][:members]).to contain_exactly(:sub_d)

      expect(relation_map[:type_four][:relationships]).to contain_exactly(:type_two, :type_one)
      expect(relation_map[:type_four][:members]).to contain_exactly(:sub_e)

      expect(relation_map[:non_sti_object][:relationships]).to contain_exactly(:type_one)
      expect(relation_map[:non_sti_object][:members]).to be_empty
    end
  end
end