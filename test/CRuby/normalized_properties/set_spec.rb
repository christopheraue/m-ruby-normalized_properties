describe NormalizedProperties::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      attr_accessor :set
      normalized_set :set, type: 'Manual', item_model: 'Item'

      attr_accessor :no_model_set
      normalized_set :no_model_set, type: 'Manual'
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
  let(:owner){ SetOwner.new }

  before{ owner.set = [item1, item2] }
  let(:item1){ Item.new 'item1' }
  let(:item2){ Item.new 'item2' }
  let(:item3){ Item.new 'item3' }
  let(:item4){ Item.new 'item4' }

  before{ owner.no_model_set = %w(item1 item2) }

  describe "#value_model" do
    context "when it's a simple attribute" do
      subject{ owner.property :no_model_set }
      it{ is_expected.to have_attributes(item_model: nil) }
    end

    context "when it's an association attribute" do
      subject{ owner.property :set }
      it{ is_expected.to have_attributes(item_model: Item) }
    end
  end

  describe "#satisfies?" do
    subject{ set.satisfies? filter }

    context "when the set has items with a simple value" do
      let(:set){ owner.property :no_model_set }

      context "when filtering by the mere existence of an item" do
        let(:filter){ true }
        it{ is_expected.to be true }

        context "when the set is empty" do
          before{ owner.no_model_set.clear }
          it{ is_expected.to be false }
        end
      end

      context "when filtering by the lack of any items" do
        let(:filter){ false }
        it{ is_expected.to be false }

        context "when the set is empty" do
          before{ owner.no_model_set.clear }
          it{ is_expected.to be true }
        end
      end

      context "when filtering by an item value" do
        context "when an item matches the filter value" do
          let(:filter){ 'item1' }
          it{ is_expected.to be true }
        end

        context "when no item does match the filter value" do
          let(:filter){ 'item3' }
          it{ is_expected.to be false }
        end
      end

      context "when filtering by a combination of filters" do
        context "when all filters must be satisfied by a single items in the set" do
          let(:filter){ NP.and filter1, filter2 }

          context "when the property satisfies the filter" do
            let(:filter1){ 'item1' }
            let(:filter2){ 'item1' }
            it{ is_expected.to be true }
          end

          context "when the property does not satisfy the filter" do
            let(:filter1){ 'item1' }
            let(:filter2){ 'item2' }
            it{ is_expected.to be false }
          end
        end

        context "when some filters must by satisfied" do
          let(:filter){ NP.or filter1, filter2 }

          context "when the property satisfies the filter" do
            let(:filter1){ 'item1' }
            let(:filter2){ 'item2' }
            it{ is_expected.to be true }
          end

          context "when the property does not satisfy the filter" do
            let(:filter1){ 'item3' }
            let(:filter2){ 'item4' }
            it{ is_expected.to be false }
          end
        end

        context "when none of the given filters must by satisfied" do
          let(:filter){ NP.not filter1, filter2 }

          context "when the property satisfies the filter" do
            let(:filter1){ 'item3' }
            let(:filter2){ 'item4' }
            it{ is_expected.to be true }
          end

          context "when the property does not satisfy the filter" do
            let(:filter1){ 'item1' }
            let(:filter2){ 'item2' }
            it{ is_expected.to be false }
          end
        end
      end
    end

    context "when the set has items of model instances" do
      let(:set){ owner.property :set }

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

      context "when filtering by a hash of item attributes" do
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
        context "when all filters must be satisfied by a single items in the set" do
          let(:filter){ NP.and filter1, filter2 }

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
          let(:filter){ NP.or filter1, filter2 }

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
          let(:filter){ NP.not filter1, filter2 }

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