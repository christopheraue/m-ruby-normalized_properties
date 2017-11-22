describe NormalizedProperties::Dependent::Set do
  subject(:dependent_set){ instance.property :dependent_set }

  let(:model) do
    Class.new do
      extend NormalizedProperties

      def initialize
        @set = %w(item1 item2 item3)
      end

      attr_reader :set
      normalized_set :set, type: 'Manual', model: 'String'

      def add_to_set(item)
        @set.push item
        property(:set).added! item
      end

      def remove_from_set(item)
        @set.delete item
        property(:set).removed! item
      end

      def dependent_set
        property(:dependent_set).value
      end
      normalized_set :dependent_set, type: 'Dependent', model: 'String',
        sources: :set,
        value: ->(sources){ sources[:set].value.map{ |item| "dependent_#{item}" } },
        filter: ->(filter){ {set: filter.sub("dependent_", "")} }
    end
  end
  let(:instance){ model.new }

  it{ is_expected.to have_attributes(owner: instance) }
  it{ is_expected.to have_attributes(name: :dependent_set) }
  it{ is_expected.to have_attributes(to_s: "#{instance}#dependent_set") }
  it{ is_expected.to have_attributes(value: %w(dependent_item1 dependent_item2 dependent_item3)) }
  it{ is_expected.to have_attributes(filter: {}) }
  it{ is_expected.to have_attributes(model: String) }

  describe "#where" do
    subject{ dependent_set.where({}) }
    it{ is_expected.to eq dependent_set }
  end

  describe "watching the addition of an item" do
    subject{ instance.add_to_set 'item4' }

    before{ dependent_set.on(:added){ |*args| addition_callback.call *args } }
    before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
    let(:addition_callback){ proc{} }
    let(:change_callback){ proc{} }

    before{ expect(addition_callback).to receive(:call).with('dependent_item4') }
    before{ expect(change_callback).to receive(:call) }
    it{ is_expected.not_to raise_error }
    after{ expect(dependent_set.value).to eq %w(dependent_item1 dependent_item2 dependent_item3 dependent_item4) }
  end

  describe "watching the removal of an item" do
    subject{ instance.remove_from_set 'item2' }

    before{ dependent_set.on(:removed){ |*args| removal_callback.call *args } }
    before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
    let(:removal_callback){ proc{} }
    let(:change_callback){ proc{} }

    before{ expect(removal_callback).to receive(:call).with('dependent_item2') }
    before{ expect(change_callback).to receive(:call) }
    it{ is_expected.not_to raise_error }
    after{ expect(dependent_set.value).to eq %w(dependent_item1 dependent_item3) }
  end
end