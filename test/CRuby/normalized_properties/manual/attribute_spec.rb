describe NormalizedProperties::Manual::Attribute do
  subject(:attribute){ instance.property :attribute }

  let(:model) do
    Class.new do
      extend NormalizedProperties

      def attribute
        'attribute_value'
      end
      normalized_attribute :attribute, type: 'Manual'
    end
  end
  let(:instance){ model.new }

  it{ is_expected.to have_attributes(owner: instance) }
  it{ is_expected.to have_attributes(name: :attribute) }
  it{ is_expected.to have_attributes(to_s: "#{instance}#attribute") }
  it{ is_expected.to have_attributes(set?: false) }
  it{ is_expected.to have_attributes(value: 'attribute_value') }

  describe "watching a changed value" do
    subject{ attribute.trigger :changed, 'changed_value', 'attribute_value' }
    before{ attribute.on(:changed){ |*args| callback.call *args } }
    let(:callback){ proc{} }
    before{ expect(callback).to receive(:call).with('changed_value', 'attribute_value') }
    it{ is_expected.not_to raise_error }
    after{ expect(attribute.value).to eq 'changed_value' }
  end
end