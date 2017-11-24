describe NormalizedProperties::Manual::Attribute do
  before do
    stub_const('PropertyOwner', Class.new do
      extend NormalizedProperties

      attr_accessor :attribute
      normalized_attribute :attribute, type: 'Manual'

      attr_accessor :association
      normalized_attribute :association, type: 'Manual'
    end)
  end

  subject(:attribute){ owner.property :attribute }
  let(:owner){ PropertyOwner.new }

  before{ owner.attribute = 'attribute_value' }

  it{ is_expected.to have_attributes(owner: owner) }
  it{ is_expected.to have_attributes(name: :attribute) }
  it{ is_expected.to have_attributes(to_s: "#{owner}#attribute") }
  it{ is_expected.to have_attributes(value: 'attribute_value') }

  describe "manual change of the attribute" do
    subject do
      owner.attribute = 'changed_value'
      owner.property(:attribute).changed!
    end

    before{ attribute.on(:changed){ |*args| callback.call *args } }
    let(:callback){ proc{} }

    before{ expect(callback).to receive(:call) }
    it{ is_expected.not_to raise_error }
    after{ expect(attribute.value).to eq 'changed_value' }
  end

  describe "#where" do
    subject{ association_property.where filter }
    let(:association_property){ owner.property :association }

    let(:association) do
      PropertyOwner.new.tap do |association|
        association.attribute = 'association_value'
      end
    end
    before{ owner.association = association }

    context "when the filter is no hash" do
      let(:filter){ :no_hash }
      it{ is_expected.to raise_error ArgumentError, 'filter no hash' }
    end

    context "when the filter is a hash" do
      context "when the filter is empty" do
        let(:filter){ {} }
        it{ is_expected.to have_attributes(value: association) }
      end

      context "when filtering by an unknown property" do
        let(:filter){ {unknown: 'value'} }
        it{ expect{ subject.value }.to raise_error NormalizedProperties::Error, "property PropertyOwner#unknown does not exist" }
      end

      context "when filtering by an attribute property" do
        context "when the property does not satisfy the filter" do
          let(:filter){ {attribute: 'another_value'} }
          it{ is_expected.to have_attributes(value: nil) }

          context "when the association does not exist" do
            let(:association){ nil }
            it{ is_expected.to have_attributes(value: nil) }
          end
        end

        context "when the property satisfies the filter" do
          let(:filter){ {attribute: 'association_value'} }
          it{ is_expected.to have_attributes(value: association) }

          context "when the association does not exist" do
            let(:association){ nil }
            it{ is_expected.to have_attributes(value: nil) }
          end
        end
      end
    end
  end
end