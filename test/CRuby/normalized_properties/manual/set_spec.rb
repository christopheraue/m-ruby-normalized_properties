describe NormalizedProperties::Manual::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      def initialize(items = [])
        @set = items
      end

      attr_reader :set
      normalized_set :set, type: 'Manual', model: 'Item'
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

      alias id __id__
      normalized_attribute :id, type: 'Manual'

      attr_reader :content
      normalized_attribute :content, type: 'Manual'
    end)
  end

  subject(:set){ owner.property :set }
  let(:owner){ SetOwner.new [item1, item2, item3] }

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
      item.set = [ItemProperty.new('setitem2')]
    end
  end

  let(:item3) do
    Item.new.tap do |item|
      item.attribute = 'attribute1'
      item.association = ItemProperty.new('association3')
      item.set = []
    end
  end

  it{ is_expected.to have_attributes(owner: owner) }
  it{ is_expected.to have_attributes(name: :set) }
  it{ is_expected.to have_attributes(to_s: "#{owner}#set") }
  it{ is_expected.to have_attributes(value: [item1, item2, item3]) }
  it{ is_expected.to have_attributes(filter: {}) }
  it{ is_expected.to have_attributes(model: Item) }

  describe "#where" do
    subject{ set.where filter }

    context "when the filter is no hash" do
      let(:filter){ :no_hash }
      it{ is_expected.to raise_error ArgumentError, 'filter no hash' }
    end

    context "when the filter is a hash" do
      context "when the filter is empty" do
        let(:filter){ {} }
        it{ is_expected.to be set }
      end

      context "when filtering by an unknown property" do
        let(:filter){ {unknown: 'value'} }
        it{ expect{ subject.value }.to raise_error NormalizedProperties::Error, "property Item#unknown does not exist" }
      end

      context "when filtering by an attribute property of the set items" do
        context "when no item matches the filter" do
          let(:filter){ {attribute: 'no_item'} }
          it{ is_expected.to have_attributes(value: []) }
        end

        context "when one item matches the filter" do
          let(:filter){ {attribute: 'attribute2'} }
          it{ is_expected.to have_attributes(value: [item2]) }
        end

        context "when multiple items match the filter" do
          let(:filter){ {attribute: 'attribute1'} }
          it{ is_expected.to have_attributes(value: [item1, item3]) }
        end
      end

      context "when filtering by an association property of the set items" do
        context "when filtering the items merely by having an association" do
          let(:filter){ {association: true} }
          it{ is_expected.to have_attributes(value: [item1, item3]) }
        end

        context "when filtering the items by having no association" do
          let(:filter){ {association: nil} }
          it{ is_expected.to have_attributes(value: [item2]) }
        end

        context "when filtering the items by the properties of their associations" do
          let(:filter){ {association: {content: 'association1'}} }
          it{ is_expected.to have_attributes(value: [item1]) }
        end

        context "when filtering the items by a directly given association" do
          let(:filter){ {association: item3.association} }
          it{ is_expected.to have_attributes(value: [item3]) }
        end

        context "when filtering the items by an invalid filter" do
          let(:filter){ {association: :symbol} }
          it{ expect{ subject.value }.to raise_error ArgumentError, "filter for property Item#association no hash or boolean" }
        end
      end

      context "when filtering by a set property of the set items" do
        context "when filtering the items by its subset having items" do
          let(:filter){ {set: true} }
          it{ is_expected.to have_attributes(value: [item1, item2]) }
        end

        context "when filtering the items by its subset having no items" do
          let(:filter){ {set: false} }
          it{ is_expected.to have_attributes(value: [item3]) }
        end

        context "when filtering the items by the properties of their associations" do
          let(:filter){ {set: {content: 'setitem1'}} }
          it{ is_expected.to have_attributes(value: [item1]) }
        end

        context "when filtering the items by a directly given association" do
          let(:filter){ {set: item2.set.first} }
          it{ is_expected.to have_attributes(value: [item2]) }
        end

        context "when filtering the items by an invalid filter" do
          let(:filter){ {set: :symbol} }
          it{ expect{ subject.value }.to raise_error ArgumentError, "filter for property Item#set no hash or boolean" }
        end
      end
    end
  end

  describe "manual addition of an item" do
    subject do
      owner.set.push item4
      owner.property(:set).added! item4
    end

    let(:item4){ Item.new }

    before{ set.on(:added){ |*args| addition_callback.call *args } }
    before{ set.on(:changed){ |*args| change_callback.call *args } }
    let(:addition_callback){ proc{} }
    let(:change_callback){ proc{} }

    before{ expect(addition_callback).to receive(:call).with(item4) }
    before{ expect(change_callback).to receive(:call) }
    it{ is_expected.not_to raise_error }
    after{ expect(set.value).to eq [item1, item2, item3, item4] }
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
    after{ expect(set.value).to eq [item1, item3] }
  end
end