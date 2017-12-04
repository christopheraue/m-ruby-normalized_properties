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

      def initialize(value)
        @value = value
      end

      attr_reader :value
      normalized_attribute :value, type: 'Manual'
    end)
  end

  subject(:set){ owner.property :set }
  let(:owner){ SetOwner.new [item1, item2] }

  let(:item1){ Item.new 'item1' }
  let(:item2){ Item.new 'item2' }
  let(:item3){ Item.new 'item3' }
  let(:item4){ Item.new 'item4' }

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
        let(:filter){ {__model_id__: item1.__model_id__} }
        it{ is_expected.to be true }
      end

      context "when the set does not contain the item" do
        let(:filter){ {__model_id__: item3.__model_id__} }
        it{ is_expected.to be false }
      end
    end

    context "when filtering by a combination of filters" do
      let(:filter){ NormalizedProperties::Filter.new(op, filter1, filter2) }

      context "when all filters must be satisfied by a single items in the set" do
        let(:op){ :and }

        context "when the property satisfies the filter" do
          let(:filter1){ {__model_id__: item1.__model_id__} }
          let(:filter2){ {value: item1.value} }
          it{ is_expected.to be true }
        end

        context "when the property does not satisfy the filter" do
          let(:filter1){ {__model_id__: item1.__model_id__} }
          let(:filter2){ {value: item2.value} }
          it{ is_expected.to be false }
        end
      end

      context "when some filters must by satisfied" do
        let(:op){ :or }

        context "when the property satisfies the filter" do
          let(:filter1){ {__model_id__: item1.__model_id__} }
          let(:filter2){ {value: item3.value} }
          it{ is_expected.to be true }
        end

        context "when the property does not satisfy the filter" do
          let(:filter1){ {__model_id__: item3.__model_id__} }
          let(:filter2){ {value: item4.value} }
          it{ is_expected.to be false }
        end
      end

      context "when none of the given filters must by satisfied" do
        let(:op){ :not }

        context "when the property satisfies the filter" do
          let(:filter1){ {__model_id__: item3.__model_id__} }
          let(:filter2){ {value: item4.value} }
          it{ is_expected.to be true }
        end

        context "when the property does not satisfy the filter" do
          let(:filter1){ {__model_id__: item1.__model_id__} }
          let(:filter2){ {value: item2.value} }
          it{ is_expected.to be false }
        end
      end
    end
  end

  describe "#where" do
    subject{ set.where filter }

    context "when the filter is no hash or filter" do
      let(:filter){ :no_hash }
      it{ is_expected.to raise_error ArgumentError, 'filter no hash or NormalizedProperties::Filter' }
    end

    context "when the filter is a hash" do
      context "when the filter is empty" do
        let(:filter){ {} }
        it{ is_expected.to be(set) }
      end
    end
  end
end