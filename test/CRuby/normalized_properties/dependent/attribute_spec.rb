describe NormalizedProperties::Dependent::Attribute do
  subject(:dependent_attribute){ instance.property :dependent_attribute }
  let(:child_dependent){ instance.property :child_dependent }

  let(:model) do
    Class.new do
      extend NormalizedProperties

      def attribute
        @value ||= 'attribute_value'
      end
      normalized_attribute :attribute, type: 'Manual'

      def attribute=(new_value)
        @value = new_value
        property(:attribute).changed!
      end

      def dependent_attribute
        property(:dependent_attribute).value
      end
      normalized_attribute :dependent_attribute, type: 'Dependent',
        sources: :attribute,
        value: ->(sources){ "dependent_#{sources[:attribute].value}" },
        filter: ->(filter){ {attribute: filter.sub("dependent_", "")} }

      def child
        @child ||= self.class.new
      end
      normalized_attribute :child, type: 'Manual'

      def child_dependent
        property(:child_dependent).value
      end
      normalized_attribute :child_dependent, type: 'Dependent',
        sources: {child: :attribute},
        value: ->(sources){ "child_dependent_#{sources[:child][:attribute].value}" },
        filter: ->(filter){ {child: {attribute: filter}} }
    end
  end
  let(:instance){ model.new }

  it{ is_expected.to have_attributes(owner: instance) }
  it{ is_expected.to have_attributes(name: :dependent_attribute) }
  it{ is_expected.to have_attributes(to_s: "#{instance}#dependent_attribute") }
  it{ is_expected.to have_attributes(set?: false) }
  it{ is_expected.to have_attributes(value: 'dependent_attribute_value') }

  describe "watching a change" do
    context "when the attribute has a symbol source" do
      subject{ instance.attribute = 'changed_value' }

      before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
      let(:callback){ proc{} }

      before{ expect(callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(dependent_attribute.value).to eq 'dependent_changed_value' }
    end

    context "when the attribute has a hash source" do
      subject{ instance.child.attribute = 'changed_value' }

      before{ child_dependent.on(:changed){ |*args| callback.call *args } }
      let(:callback){ proc{} }

      before{ expect(callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(child_dependent.value).to eq 'child_dependent_changed_value' }
    end
  end
end