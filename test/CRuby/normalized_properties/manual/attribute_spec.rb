describe NormalizedProperties::Manual::Attribute do
  subject(:attribute){ instance.property :attribute }

  let(:model) do
    Class.new do
      extend NormalizedProperties

      def attribute
        @value ||= 'attribute_value'
      end

      def attribute=(new_value)
        @value = new_value
        property(:attribute).changed!
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

  describe "watching a change" do
    subject{ instance.attribute = 'changed_value' }

    before{ attribute.on(:changed){ |*args| callback.call *args } }
    let(:callback){ proc{} }

    before{ expect(callback).to receive(:call) }
    it{ is_expected.not_to raise_error }
    after{ expect(attribute.value).to eq 'changed_value' }
  end
end