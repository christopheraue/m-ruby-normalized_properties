describe NormalizedProperties::Dependent::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      def initialize(items = [])
        @set = items
      end

      attr_reader :set
      normalized_set :set, type: 'Manual', item_model: 'Item'

      def child
        @child ||= self.class.new
      end
      normalized_attribute :child, type: 'Manual'

      normalized_set :symbol_dependent, type: 'Dependent', item_model: 'DependentItem',
        sources: :set,
        value: ->(sources){ sources[:set].value.map{ |item| DependentItem.new item } },
        filter: ->(filter){ {set: (filter.is_a? DependentItem) ? filter.item : filter} }

      normalized_set :array_dependent, type: 'Dependent', item_model: 'DependentItem',
        sources: [:set],
        value: ->(sources){ sources[:set].value.map{ |item| DependentItem.new item } },
        filter: ->(filter){ {set: (filter.is_a? DependentItem) ? filter.item : filter} }

      normalized_set :hash_dependent, type: 'Dependent', item_model: 'DependentItem',
        sources: {child: :set},
        value: ->(sources){ sources[:child][:set].value.map{ |item| DependentItem.new item } },
        filter: ->(filter){ {child: {set: (filter.is_a? DependentItem) ? filter.item : filter}} }

      normalized_set :mixed_dependent, type: 'Dependent', item_model: 'DependentItem',
        sources: {child: [child: :set]},
        value: ->(sources){ sources[:child][:child][:set].value.map{ |item| DependentItem.new item } },
        filter: ->(filter){ {child: {child: {set: (filter.is_a? DependentItem) ? filter.item : filter}}} }
    end)

    stub_const('Item', Class.new do
      extend NormalizedProperties

      alias id __id__
      normalized_attribute :id, type: 'Manual'

      attr_accessor :attribute
      normalized_attribute :attribute, type: 'Manual'

      attr_accessor :association
      normalized_attribute :association, type: 'Manual', value_model: 'ItemProperty'

      attr_accessor :set
      normalized_set :set, type: 'Manual', item_model: 'ItemProperty'
    end)

    stub_const('ItemProperty', Class.new do
      extend NormalizedProperties

      def initialize(content)
        @content = content
      end

      alias id __id__
      normalized_attribute :id, type: 'Manual'

      attr_reader :content
      normalized_attribute :content, type: 'Manual'
    end)

    stub_const('DependentItem', Class.new do
      extend NormalizedProperties

      def initialize(item)
        @item = item
      end
      attr_reader :item
      normalized_attribute :item, type: 'Manual'

      normalized_attribute :attribute, type: 'Dependent',
        sources: {item: :attribute},
        value: ->(sources){ sources[:item][:attribute].value },
        filter: ->(filter){ {item: {attribute: filter}} }

      def association
        property(:association).value
      end
      normalized_attribute :association, type: 'Dependent', value_model: 'ItemProperty',
        sources: {item: :association},
        value: ->(sources){ sources[:item][:association].value },
        filter: ->(filter){ {item: {association: filter}} }

      def set
        property(:set).value
      end
      normalized_set :set, type: 'Dependent', item_model: 'ItemProperty',
        sources: {item: :set},
        value: ->(sources){ sources[:item][:set].value },
        filter: ->(filter){ {item: {set: filter}} }

      def ==(other)
        @item == other.item
      end
      alias eql? ==

      def hash
        @item.hash
      end
    end)
  end

  shared_examples "for a set property" do |property_name|
    subject(:dependent_set){ dependent_owner.property property_name }

    let(:dependent_owner){ SetOwner.new }

    let(:item1) do
      Item.new.tap do |item|
        item.attribute = 'attribute1'
        item.association = ItemProperty.new('association1')
        item.set = [ItemProperty.new('setitem1')]
      end
    end
    let(:dependent_item1){ DependentItem.new item1 }

    let(:item2) do
      Item.new.tap do |item|
        item.attribute = 'attribute2'
        item.association = nil
        item.set = [ItemProperty.new('setitem2')]
      end
    end
    let(:dependent_item2){ DependentItem.new item2 }

    let(:item3) do
      Item.new.tap do |item|
        item.attribute = 'attribute1'
        item.association = ItemProperty.new('association3')
        item.set = []
      end
    end
    let(:dependent_item3){ DependentItem.new item3 }

    let(:item4){ Item.new }
    let(:dependent_item4){ DependentItem.new item4 }

    before{ set_owner.set.concat [item1, item2, item3] }

    it{ is_expected.to have_attributes(owner: dependent_owner) }
    it{ is_expected.to have_attributes(name: property_name) }
    it{ is_expected.to have_attributes(to_s: "#{dependent_owner}##{property_name}") }

    describe "#value" do
      subject{ dependent_set.value }

      context "when the set has not been filtered" do
        it{ is_expected.to eq [dependent_item1, dependent_item2, dependent_item3] }
      end

      context "when the set has been filtered" do
        let(:dependent_set){ dependent_owner.property(property_name).where filter }

        context "when the filter is empty" do
          let(:filter){ {} }
          it{ is_expected.to eq [dependent_item1, dependent_item2, dependent_item3] }
        end

        context "when filtering by an unknown property" do
          let(:filter){ {unknown: 'value'} }
          it{ is_expected.to raise_error NormalizedProperties::Error, "property DependentItem#unknown does not exist" }
        end

        context "when filtering by an attribute property of the set items" do
          context "when no item matches the filter" do
            let(:filter){ {attribute: 'no_item'} }
            it{ is_expected.to eq [] }
          end

          context "when one item matches the filter" do
            let(:filter){ {attribute: 'attribute2'} }
            it{ is_expected.to eq [dependent_item2] }
          end

          context "when multiple items match the filter" do
            let(:filter){ {attribute: 'attribute1'} }
            it{ is_expected.to eq [dependent_item1, dependent_item3] }
          end
        end

        context "when filtering by an association property of the set items" do
          context "when filtering the items merely by having an association" do
            let(:filter){ {association: true} }
            it{ is_expected.to eq [dependent_item1, dependent_item3] }
          end

          context "when filtering the items by having no association" do
            let(:filter){ {association: nil} }
            it{ is_expected.to eq [dependent_item2] }
          end

          context "when filtering the items by the properties of their associations" do
            let(:filter){ {association: {content: 'association1'}} }
            it{ is_expected.to eq [dependent_item1] }
          end

          context "when filtering the items by a directly given association" do
            let(:filter){ {association: dependent_item3.association} }
            it{ is_expected.to eq [dependent_item3] }
          end

          context "when filtering the items by an invalid filter" do
            let(:filter){ {association: :symbol} }
            it{ is_expected.to eq [] }
          end
        end

        context "when filtering by a set property of the set items" do
          context "when filtering the items by its subset having items" do
            let(:filter){ {set: true} }
            it{ is_expected.to eq [dependent_item1, dependent_item2] }
          end

          context "when filtering the items by its subset having no items" do
            let(:filter){ {set: false} }
            it{ is_expected.to eq [dependent_item3] }
          end

          context "when filtering the items by the properties of their associations" do
            let(:filter){ {set: {content: 'setitem1'}} }
            it{ is_expected.to eq [dependent_item1] }
          end

          context "when filtering the items by a directly given association" do
            let(:filter){ {set: dependent_item2.set.first} }
            it{ is_expected.to eq [dependent_item2] }
          end

          context "when filtering the items by an invalid filter" do
            let(:filter){ {set: :symbol} }
            it{ is_expected.to eq [] }
          end
        end
      end
    end

    describe "#satisfies?" do
      subject{ dependent_set.satisfies? filter }

      context "when the filter is a hash with property sub filters" do
        context "when the set does not satisfy the filter" do
          let(:filter){ {attribute: "another value"} }
          it{ is_expected.to be false }
        end

        context "when the set satisfies the filter" do
          let(:filter){ {attribute: 'attribute1'} }
          it{ is_expected.to be true }
        end
      end

      context "when the filter is an item directly" do
        context "when the set does not satisfy the filter" do
          let(:filter){ dependent_item4 }
          it{ is_expected.to be false }
        end

        context "when the set satisfies the filter" do
          let(:filter){ dependent_item1 }
          it{ is_expected.to be true }
        end
      end
    end

    describe "watching the addition of an item" do
      subject do
        set_owner.set.push item4
        set_owner.property(:set).added! item4
      end

      before{ dependent_set.on(:added){ |*args| addition_callback.call *args } }
      before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
      let(:addition_callback){ proc{} }
      let(:change_callback){ proc{} }

      before{ expect(addition_callback).to receive(:call).with(dependent_item4) }
      before{ expect(change_callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(dependent_set.value).to eq [dependent_item1, dependent_item2, dependent_item3,
        dependent_item4] }
    end

    describe "watching the removal of an item" do
      subject do
        set_owner.set.delete item2
        set_owner.property(:set).removed! item2
      end

      before{ dependent_set.on(:removed){ |*args| removal_callback.call *args } }
      before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
      let(:removal_callback){ proc{} }
      let(:change_callback){ proc{} }

      before{ expect(removal_callback).to receive(:call).with(dependent_item2) }
      before{ expect(change_callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(dependent_set.value).to eq [dependent_item1, dependent_item3] }
    end
  end

  context "when the set has a symbol source" do
    let(:set_owner){ dependent_owner }
    include_examples "for a set property", :symbol_dependent
  end

  context "when the set has an array source" do
    let(:set_owner){ dependent_owner }
    include_examples "for a set property", :array_dependent
  end

  context "when the set has a hash source" do
    let(:set_owner){ dependent_owner.child }
    include_examples "for a set property", :hash_dependent
  end

  context "when the set has a mixed source" do
    let(:set_owner){ dependent_owner.child.child }
    include_examples "for a set property", :mixed_dependent
  end
end