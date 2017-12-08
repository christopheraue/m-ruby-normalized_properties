describe NormalizedProperties::Set::Filter do
  before{ stub_const('SetOwner', Class.new{ extend NormalizedProperties }) }

  subject(:set_filter){ set.filter }
  let(:set){ owner.property(set_name).where filter }
  let(:owner){ SetOwner.new }

  describe "the filter of a set having no model" do
    let(:set_name){ :set }
    let(:filter){ NP.or('item1', 'item2') }

    before do
      class SetOwner
        attr_accessor :set
        normalized_set :set, type: 'Manual'
      end
    end

    it{ is_expected.to have_attributes op: :and }
    it{ is_expected.to have_attributes parts: [have_attributes(op: :or, parts: %w(item1 item2))] }
    it{ is_expected.to have_attributes dependencies_resolved: be(set_filter) }
  end

  describe "the filter of a set having a model" do
    before do
      class SetOwner
        attr_accessor :set
        normalized_set :set, type: 'Manual', model: 'Item'
      end

      stub_const('Item', Class.new do
        extend NormalizedProperties

        attr_accessor :attribute
        normalized_attribute :attribute, type: 'Manual'
      end)
    end

    context "when it is a set filtered by properties of its items" do
      let(:set_name){ :set }
      let(:filter){ NP.or({attribute: 'attribute1'}, item) }

      let(:item){ Item.new }

      it{ is_expected.to have_attributes op: :and }
      it{ is_expected.to have_attributes parts: [have_attributes(op: :or, parts:
        [{attribute: 'attribute1'}, item])] }
      it{ is_expected.to have_attributes dependencies_resolved: have_attributes(op: :and, parts:
        [have_attributes(op: :or, parts: [{attribute: 'attribute1'}, item])]) }
    end

    context "when it is a dependent set" do
      before do
        class SetOwner
          normalized_set :dependent_set, type: 'Dependent', model: 'DependentItem',
            sources: :set,
            sources_filter: ->(filter){ {set: filter} },
            value: ->(sources){ sources[:set].value.map{ |item| DependentItem.new item } }
        end

        stub_const('DependentItem', Class.new do
          extend NormalizedProperties

          def initialize(item)
            @item = item
          end
          attr_reader :item
          normalized_attribute :item, type: 'Manual', model: 'Item'

          normalized_attribute :attribute, type: 'Dependent',
            sources: {item: :attribute},
            sources_filter: ->(filter){ {item: {attribute: filter}} },
            value: ->(sources){ sources[:item][:attribute].value }
        end)
      end

      let(:set_name){ :dependent_set }
      let(:filter){ NP.or({attribute: 'attribute1'}, dependent_item) }

      let(:item){ Item.new }
      let(:dependent_item){ DependentItem.new item }

      it{ is_expected.to have_attributes op: :and }
      it{ is_expected.to have_attributes parts: [have_attributes(op: :or,
        parts: [{attribute: 'attribute1'}, dependent_item])] }
      it{ is_expected.to have_attributes dependencies_resolved: have_attributes(op: :and, parts:
        [have_attributes(op: :or, parts: [{item: {attribute: 'attribute1'}}, dependent_item])]) }
    end

    context "when it is a set filtered by dependent properties of its items" do
      before do
        class Item
          normalized_attribute :dependent_attribute, type: 'Dependent', model: 'DependentItem',
            sources: :attribute,
            sources_filter: ->(filter){ {attribute: filter} },
            value: ->(sources){ DependentItem.new sources[:attribute].value }

          normalized_attribute :dependent_dependent_attribute, type: 'Dependent', model: 'ItemProperty',
            sources: :dependent_attribute,
            sources_filter: ->(filter){ {dependent_attribute: filter} },
            value: ->(sources){ sources[:dependent_attribute].value }
        end
      end

      context "when filtering by a dependent property" do
        let(:set_name){ :set }
        let(:filter){ {dependent_attribute: 'item2'} }

        it{ is_expected.to have_attributes op: :and, parts: [dependent_attribute: 'item2'] }
        it{ is_expected.to have_attributes dependencies_resolved: have_attributes(op: :and, parts:
          [attribute: 'item2']) }
      end

      context "when filtering by a dependent property depending on another dependent property" do
        let(:set_name){ :set }
        let(:filter){ {dependent_dependent_attribute: 'item2'} }

        it{ is_expected.to have_attributes op: :and, parts: [dependent_dependent_attribute: 'item2'] }
        it{ is_expected.to have_attributes dependencies_resolved: have_attributes(op: :and, parts:
          [attribute: 'item2']) }
      end
    end
  end
end