describe NormalizedProperties::Manual::Set do
  subject(:set){ instance.property :set }

  before do
    stub_const('Item', Class.new(String) do
      extend NormalizedProperties
      normalized_attribute :to_s, type: 'Manual'
    end)

    stub_const('Set', Class.new do
      extend NormalizedProperties

      def initialize(items = [])
        @set = items
      end

      attr_reader :set

      def add_to_set(item)
        @set.push item
        property(:set).added! item
      end

      def remove_from_set(item)
        @set.delete item
        property(:set).removed! item
      end

      normalized_set :set, type: 'Manual', model: 'Item'
    end)
  end

  let(:item1){ Item.new 'item' }
  let(:item2){ Item.new 'another_item' }
  let(:item3){ Item.new 'item' }
  let(:instance){ Set.new [item1, item2, item3] }

  it{ is_expected.to have_attributes(owner: instance) }
  it{ is_expected.to have_attributes(name: :set) }
  it{ is_expected.to have_attributes(to_s: "#{instance}#set") }
  it{ is_expected.to have_attributes(set?: true) }
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
      context "when no item matches the filter" do
        let(:filter){ {to_s: 'no_item'} }
        it{ is_expected.to have_attributes(value: []) }
      end

      context "when one item matches the filter" do
        let(:filter){ {to_s: 'another_item'} }
        it{ is_expected.to have_attributes(value: [item2]) }
      end

      context "when multiple items match the filter" do
        let(:filter){ {to_s: 'item'} }
        it{ is_expected.to have_attributes(value: [item1, item3]) }
      end

      context "when filtering by an unknown property" do
        let(:filter){ {unknown: 'item'} }
        it{ is_expected.to raise_error ArgumentError, "filter contains unknown property Item#unknown" }
      end
    end

    context "when the set items have an association property that can be filtered by" do
      before do
        Item.class_eval do
          attr_accessor :association
          normalized_attribute :association, type: 'Manual', model: 'ItemAssociation'
        end

        stub_const('ItemAssociation', Class.new(String) do
          extend NormalizedProperties

          def initialize(content)
            @content = content
          end

          alias id __id__
          normalized_attribute :id, type: 'Manual'

          attr_reader :content
          normalized_attribute :content, type: 'Manual'
        end)

        item1.association = ItemAssociation.new('assoc1')
        item3.association = ItemAssociation.new('assoc3')
      end

      context "when filtering the items merely by having an association" do
        let(:filter){ {association: true} }
        it{ is_expected.to have_attributes(value: [item1, item3]) }
      end

      context "when filtering the items by having no association" do
        let(:filter){ {association: false} }
        it{ is_expected.to have_attributes(value: [item2]) }
      end

      context "when filtering the items by the properties of their associations" do
        let(:filter){ {association: {content: 'assoc1'}} }
        it{ is_expected.to have_attributes(value: [item1]) }
      end

      context "when filtering the items by a directly given association" do
        let(:filter){ {association: item3.association} }
        it{ is_expected.to have_attributes(value: [item3]) }
      end

      context "when filtering the items by an invalid filter" do
        let(:filter){ {association: :symbol} }
        it{ is_expected.to raise_error ArgumentError, "filter for property Item#association no hash or boolean" }
      end
    end

    context "when the set items have a set property that can be filtered by" do
      before do
        Item.class_eval do
          attr_accessor :set
          normalized_set :set, type: 'Manual', model: 'SubItem'
        end

        stub_const('SubItem', Class.new(String) do
          extend NormalizedProperties

          def initialize(content)
            @content = content
          end

          alias id __id__
          normalized_attribute :id, type: 'Manual'

          attr_reader :content
          normalized_attribute :content, type: 'Manual'
        end)

        item1.set = [SubItem.new('subitem1')]
        item2.set = []
        item3.set = [SubItem.new('subitem3')]
      end

      context "when filtering the items by its subset having items" do
        let(:filter){ {set: true} }
        it{ is_expected.to have_attributes(value: [item1, item3]) }
      end

      context "when filtering the items by its subset having no items" do
        let(:filter){ {set: false} }
        it{ is_expected.to have_attributes(value: [item2]) }
      end

      context "when filtering the items by the properties of their associations" do
        let(:filter){ {set: {content: 'subitem1'}} }
        it{ is_expected.to have_attributes(value: [item1]) }
      end

      context "when filtering the items by a directly given association" do
        let(:filter){ {set: item3.set.first} }
        it{ is_expected.to have_attributes(value: [item3]) }
      end

      context "when filtering the items by an invalid filter" do
        let(:filter){ {set: :symbol} }
        it{ is_expected.to raise_error ArgumentError, "filter for property Item#set no hash or boolean" }
      end
    end
  end

  describe "watching the addition of an item" do
    subject{ instance.add_to_set item4 }
    let(:item4){ Item.new 'item4' }

    before{ set.on(:added){ |*args| addition_callback.call *args } }
    before{ set.on(:changed){ |*args| change_callback.call *args } }
    let(:addition_callback){ proc{} }
    let(:change_callback){ proc{} }

    before{ expect(addition_callback).to receive(:call).with(item4) }
    before{ expect(change_callback).to receive(:call) }
    it{ is_expected.not_to raise_error }
    after{ expect(set.value).to eq [item1, item2, item3, item4] }
  end

  describe "watching the removal of an item" do
    subject{ instance.remove_from_set item2 }

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