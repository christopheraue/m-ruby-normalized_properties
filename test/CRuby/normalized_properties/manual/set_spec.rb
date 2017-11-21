describe NormalizedProperties::Manual::Set do
  subject(:set){ instance.property :set }

  before do
    stub_const('Item', Class.new(String))

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

  let(:item1){ Item.new 'item1' }
  let(:item2){ Item.new 'item2' }
  let(:item3){ Item.new 'item3' }
  let(:instance){ Set.new [item1, item2, item3] }

  it{ is_expected.to have_attributes(owner: instance) }
  it{ is_expected.to have_attributes(name: :set) }
  it{ is_expected.to have_attributes(to_s: "#{instance}#set") }
  it{ is_expected.to have_attributes(set?: true) }
  it{ is_expected.to have_attributes(value: [item1, item2, item3]) }
  it{ is_expected.to have_attributes(filter: {}) }
  it{ is_expected.to have_attributes(model: Item) }

  describe "#where" do
    subject{ set.where :filter }
    it{ is_expected.to raise_error NormalizedProperties::Error, 'manual set not filterable' }
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