describe NormalizedProperties::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      def initialize(items = [])
        @set = items
      end

      attr_reader :set
      normalized_set :set, type: 'Manual'
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
        before{ owner.set.delete item2 }
        let(:filter){ {id: item2.id} }
        it{ is_expected.to be false }
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
        let(:filter){ {attribute: 'value'} }
        it{ is_expected.to be_a(described_class).and have_attributes(filter: filter) }
      end
    end
  end
end