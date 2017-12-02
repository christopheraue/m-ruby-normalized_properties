describe NormalizedProperties::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      def initialize(items = [])
        @set = items
      end

      attr_reader :set
      normalized_set :set, type: 'Manual', item_model: 'Item'
    end)

    stub_const('Item', Class.new do
      extend NormalizedProperties

      alias id __id__
      normalized_attribute :id, type: 'Manual'
    end)
  end

  subject(:set){ owner.property :set }
  let(:owner){ SetOwner.new [item1, item2, item3] }

  let(:item1){ Item.new }
  let(:item2){ Item.new }
  let(:item3){ Item.new }
  let(:item4){ Item.new }
  let(:item5){ Item.new }

  it{ is_expected.to have_attributes(item_model: Item) }

  describe "#satisfies?" do
    subject{ set.satisfies? filter }

    context "when the filter is an arbitrary value" do
      let(:filter){ 'arbitrary' }
      it{ is_expected.to be false }
    end

    context "when filtering by the mere existence of an item" do
      let(:filter){ true }
      it{ is_expected.to be true }

      context "when the set is empty" do
        before{ owner.set.clear }
        it{ is_expected.to be false }
      end
    end

    context "when filtering by the lack of any items" do
      let(:filter){ false }
      it{ is_expected.to be false }

      context "when the set is empty" do
        before{ owner.set.clear }
        it{ is_expected.to be true }
      end
    end

    context "when filtering by a specific item" do
      context "when the set contains the item" do
        let(:filter){ {id: item1.id} }
        it{ is_expected.to be true }
      end

      context "when the set does not contain the item" do
        let(:filter){ {id: item4.id} }
        it{ is_expected.to be false }
      end
    end

    context "when filtering by a combination of filters" do
      let(:filter){ NormalizedProperties::Filter.new(op, filter1, filter2) }

      context "when all filters must by satisfied by any items of the set" do
        let(:op){ :all }

        context "when the property satisfies the filter" do
          let(:filter1){ {id: item1.id} }
          let(:filter2){ {id: item2.id} }
          it{ is_expected.to be true }
        end

        context "when the property does not satisfy the filter" do
          let(:filter1){ {id: item1.id} }
          let(:filter2){ {id: item4.id} }
          it{ is_expected.to be false }
        end
      end

      context "when some filters must by satisfied" do
        let(:op){ :some }

        context "when the property satisfies the filter" do
          let(:filter1){ {id: item1.id} }
          let(:filter2){ {id: item4.id} }
          it{ is_expected.to be true }
        end

        context "when the property does not satisfy the filter" do
          let(:filter1){ {id: item4.id} }
          let(:filter2){ {id: item5.id} }
          it{ is_expected.to be false }
        end
      end

      context "when exactly one and no more filters must by satisfied" do
        let(:op){ :one }

        context "when the property satisfies the filter" do
          let(:filter1){ {id: item1.id} }
          let(:filter2){ {id: item4.id} }
          it{ is_expected.to be true }
        end

        context "when the property does not satisfy the filter" do
          let(:filter1){ {id: item1.id} }
          let(:filter2){ {id: item2.id} }
          it{ is_expected.to be false }
        end
      end

      context "when none of the given filters must by satisfied" do
        let(:op){ :none }

        context "when the property satisfies the filter" do
          let(:filter1){ {id: item4.id} }
          let(:filter2){ {id: item5.id} }
          it{ is_expected.to be true }
        end

        context "when the property does not satisfy the filter" do
          let(:filter1){ {id: item1.id} }
          let(:filter2){ {id: item4.id} }
          it{ is_expected.to be false }
        end
      end
    end
  end

  describe "#where" do
    subject{ set.where filter }

    context "when the filter is no hash" do
      let(:filter){ :no_hash }
      it{ is_expected.to raise_error ArgumentError, 'filter no hash' }
    end

    context "when the filter is a hash" do
      context "when the filter is empty" do
        let(:filter){ {} }
        it{ is_expected.to be(set).and have_attributes(filter: filter) }
      end

      context "when the filter is not empty" do
        before{ Item.normalized_attribute :attribute, type: 'Manual' }

        let(:filter){ {attribute: 'value'} }
        it{ is_expected.to be_a(described_class).and have_attributes(filter: filter) }
      end

      context "when the set is filtered twice" do
        before{ Item.normalized_attribute :this, type: 'Manual' }
        before{ Item.normalized_attribute :nested, type: 'Manual' }
        before{ Item.normalized_attribute :second, type: 'Manual' }

        let(:set){ owner.property(:set).where(this: {will: 'be replaced'}, nested: 'filter') }
        let(:filter){ {this: {will: 'stay'}, second: 'filter'} }
        it{ is_expected.to be_a(described_class).and have_attributes(
          filter: {this: {will: 'stay'}, nested: 'filter', second: 'filter'}) }
      end
    end
  end
end