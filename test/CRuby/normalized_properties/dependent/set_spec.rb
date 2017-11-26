describe NormalizedProperties::Dependent::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      def initialize(items = [])
        @set = items
      end

      attr_reader :set
      normalized_set :set, type: 'Manual'

      def child
        @child ||= self.class.new
      end
      normalized_attribute :child, type: 'Manual'

      normalized_set :symbol_dependent, type: 'Dependent',
        sources: :set,
        value: ->(sources){ sources[:set].value.map{ |item| DependentItem.new item } },
        filter: ->(filter){ {set: (filter.is_a? DependentItem) ? filter.item : filter} }

      normalized_set :array_dependent, type: 'Dependent',
        sources: [:set],
        value: ->(sources){ sources[:set].value.map{ |item| DependentItem.new item } },
        filter: ->(filter){ {set: (filter.is_a? DependentItem) ? filter.item : filter} }

      normalized_set :hash_dependent, type: 'Dependent',
        sources: {child: :set},
        value: ->(sources){ sources[:child][:set].value.map{ |item| DependentItem.new item } },
        filter: ->(filter){ {child: {set: (filter.is_a? DependentItem) ? filter.item : filter}} }

      normalized_set :mixed_dependent, type: 'Dependent',
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
      end
    end
    let(:dependent_item1){ DependentItem.new item1 }

    let(:item2) do
      Item.new.tap do |item|
        item.attribute = 'attribute2'
      end
    end
    let(:dependent_item2){ DependentItem.new item2 }

    let(:item3) do
      Item.new.tap do |item|
        item.attribute = 'attribute1'
      end
    end
    let(:dependent_item3){ DependentItem.new item3 }

    let(:item4){ Item.new }
    let(:dependent_item4){ DependentItem.new item4 }

    before{ set_owner.set.concat [item1, item2, item3] }

    it{ is_expected.to have_attributes(owner: dependent_owner) }
    it{ is_expected.to have_attributes(name: property_name) }
    it{ is_expected.to have_attributes(to_s: "#{dependent_owner}##{property_name}") }
    it{ is_expected.to have_attributes(value: [dependent_item1, dependent_item2, dependent_item3]) }

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

    describe "#where" do
      subject{ dependent_set.where({}) }
      it{ is_expected.to eq dependent_set }
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