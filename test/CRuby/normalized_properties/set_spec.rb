describe NormalizedProperties::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      def initialize
        @set = []
      end

      attr_reader :set
      normalized_set :set, type: 'Manual'
    end)
  end

  subject(:set){ owner.property :set }
  let(:owner){ SetOwner.new }

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