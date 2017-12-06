describe NormalizedProperties::Manual::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      attr_accessor :set
      normalized_set :set, type: 'Manual', model: 'Item'

      attr_accessor :no_model_set
      normalized_set :no_model_set, type: 'Manual'
    end)

    stub_const('Item', Class.new do
      extend NormalizedProperties

      attr_accessor :attribute
      normalized_attribute :attribute, type: 'Manual'

      attr_accessor :association
      normalized_attribute :association, type: 'Manual', model: 'ItemProperty'

      attr_accessor :set
      normalized_set :set, type: 'Manual', model: 'ItemProperty'
    end)

    stub_const('ItemProperty', Class.new do
      extend NormalizedProperties

      def initialize(content)
        @content = content
      end

      attr_reader :content
      normalized_attribute :content, type: 'Manual'
    end)
  end

  subject(:set){ owner.property :set }
  let(:owner){ SetOwner.new }
  before{ owner.set = [item1, item2] }
  before{ owner.no_model_set = %w(item1 item2) }

  let(:item1) do
    Item.new.tap do |item|
      item.attribute = 'attribute1'
      item.association = ItemProperty.new('association1')
      item.set = [ItemProperty.new('setitem1')]
    end
  end

  let(:item2) do
    Item.new.tap do |item|
      item.attribute = 'attribute2'
      item.association = nil
      item.set = []
    end
  end

  it{ is_expected.to have_attributes(owner: owner) }
  it{ is_expected.to have_attributes(name: :set) }
  it{ is_expected.to have_attributes(to_s: "#{owner}#set") }

  describe "#value" do
    subject{ set.value }

    context "when the set has items with a simple value" do
      context "when the set has not been filtered" do
        let(:set){ owner.property :no_model_set }
        it { is_expected.to eq %w(item1 item2) }
      end

      context "when the set has been filtered" do
        let(:set){ owner.property(:no_model_set).where filter }

        context "when the filter is empty" do
          let(:filter){ nil }
          it{ is_expected.to eq %w(item1 item2) }
        end

        context "when no item matches the filter" do
          let(:filter){ 'no_item' }
          it{ is_expected.to eq [] }
        end

        context "when one item matches the filter" do
          let(:filter){ 'item2' }
          it{ is_expected.to eq %w(item2) }
        end

        context "when multiple items match the filter" do
          let(:filter){ NP.or 'item1', 'item2' }
          it{ is_expected.to eq %w(item1 item2) }
        end
      end
    end

    context "when the set has items of model instances" do
      context "when the set has not been filtered" do
        let(:set){ owner.property :set }
        it { is_expected.to eq [item1, item2] }
      end

      context "when the set has been filtered" do
        let(:set){ owner.property(:set).where filter }

        context "when the filter is empty" do
          let(:filter){ {} }
          it{ is_expected.to eq [item1, item2] }
        end

        context "when filtering by an unknown property" do
          let(:filter){ {unknown: 'value'} }
          it{ is_expected.to raise_error NormalizedProperties::Error, "property Item#unknown does not exist" }
        end

        context "when filtering by an attribute property of the set items" do
          context "when no item matches the filter" do
            let(:filter){ {attribute: 'no_item'} }
            it{ is_expected.to eq [] }
          end

          context "when one item matches the filter" do
            let(:filter){ {attribute: 'attribute2'} }
            it{ is_expected.to eq [item2] }
          end

          context "when multiple items match the filter" do
            let(:filter){ NP.or({attribute: 'attribute1'}, {attribute: 'attribute2'})  }
            it{ is_expected.to eq [item1, item2] }
          end
        end

        context "when filtering by an association property of the set items" do
          context "when filtering the items merely by having an association" do
            let(:filter){ {association: true} }
            it{ is_expected.to eq [item1] }
          end

          context "when filtering the items by having no association" do
            let(:filter){ {association: nil} }
            it{ is_expected.to eq [item2] }
          end

          context "when filtering the items by the properties of their associations" do
            let(:filter){ {association: {content: 'association1'}} }
            it{ is_expected.to eq [item1] }
          end

          context "when filtering the items by a directly given association" do
            let(:filter){ {association: item2.association} }
            it{ is_expected.to eq [item2] }
          end

          context "when filtering the items by an invalid filter" do
            let(:filter){ {association: :symbol} }
            it{ is_expected.to eq [] }
          end
        end

        context "when filtering by a set property of the set items" do
          context "when filtering the items by its subset having items" do
            let(:filter){ {set: true} }
            it{ is_expected.to eq [item1] }
          end

          context "when filtering the items by its subset having no items" do
            let(:filter){ {set: false} }
            it{ is_expected.to eq [item2] }
          end

          context "when filtering the items by the properties of their associations" do
            let(:filter){ {set: {content: 'setitem1'}} }
            it{ is_expected.to eq [item1] }
          end

          context "when filtering the items by a directly given association" do
            let(:filter){ {set: item1.set.first} }
            it{ is_expected.to eq [item1] }
          end

          context "when filtering the items by an invalid filter" do
            let(:filter){ {set: :symbol} }
            it{ is_expected.to eq [] }
          end
        end
      end
    end
  end

  describe "manual addition of an item" do
    subject do
      owner.set.push item3
      owner.property(:set).added! item3
    end

    let(:item3){ Item.new }

    before{ set.on(:added){ |*args| addition_callback.call *args } }
    before{ set.on(:changed){ |*args| change_callback.call *args } }
    let(:addition_callback){ proc{} }
    let(:change_callback){ proc{} }

    before{ expect(addition_callback).to receive(:call).with(item3) }
    before{ expect(change_callback).to receive(:call) }
    it{ is_expected.not_to raise_error }
    after{ expect(set.value).to eq [item1, item2, item3] }
  end

  describe "manual removal of an item" do
    subject do
      owner.set.delete item2
      owner.property(:set).removed! item2
    end

    before{ set.on(:removed){ |*args| removal_callback.call *args } }
    before{ set.on(:changed){ |*args| change_callback.call *args } }
    let(:removal_callback){ proc{} }
    let(:change_callback){ proc{} }

    before{ expect(removal_callback).to receive(:call).with(item2) }
    before{ expect(change_callback).to receive(:call) }
    it{ is_expected.not_to raise_error }
    after{ expect(set.value).to eq [item1] }
  end
end