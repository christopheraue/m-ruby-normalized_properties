describe NormalizedProperties::Dependent::Attribute do
  before do
    stub_const('AttributeOwner', Class.new do
      extend NormalizedProperties

      def attribute
        @value ||= 'attribute_value'
      end
      normalized_attribute :attribute, type: 'Manual'

      def attribute=(new_value)
        @value = new_value
        property(:attribute).changed!
      end

      def child
        @child ||= self.class.new
      end
      normalized_attribute :child, type: 'Manual'

      normalized_attribute :symbol_dependent, type: 'Dependent',
        sources: :attribute,
        value: ->(sources){ "dependent_#{sources[:attribute].value}" },
        filter: ->(filter){ {attribute: filter.sub("dependent_", "")} }

      normalized_attribute :array_dependent, type: 'Dependent',
        sources: [:attribute],
        value: ->(sources){ "dependent_#{sources[:attribute].value}" },
        filter: ->(filter){ {attribute: filter.sub("dependent_", "")} }

      normalized_attribute :hash_dependent, type: 'Dependent',
        sources: {child: :attribute},
        value: ->(sources){ "dependent_#{sources[:child][:attribute].value}" },
        filter: ->(filter){ {child: {attribute: filter.sub("dependent_", "")}} }

      normalized_attribute :mixed_dependent, type: 'Dependent',
        sources: {child: [child: :attribute]},
        value: ->(sources){ "dependent_#{sources[:child][:child][:attribute].value}" },
        filter: ->(filter){ {child: {attribute: filter.sub("dependent_", "")}} }
    end)
  end
  
  let(:dependent_owner){ AttributeOwner.new }

  shared_examples "for an attribute property" do|property_name|
    subject(:dependent_attribute){ dependent_owner.property property_name }

    it{ is_expected.to have_attributes(owner: dependent_owner) }
    it{ is_expected.to have_attributes(name: property_name) }
    it{ is_expected.to have_attributes(to_s: "#{dependent_owner}##{property_name}") }
    it{ is_expected.to have_attributes(value: 'dependent_attribute_value') }

    describe "watching a change" do
      subject{ attribute_owner.attribute = 'changed_value' }

      before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
      let(:callback){ proc{} }

      before{ expect(callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(dependent_attribute.value).to eq 'dependent_changed_value' }
    end

    describe "#satisfies?" do
      subject{ dependent_attribute.satisfies? filter }

      context "when the attribute does not satisfy the filter" do
        let(:filter){ "another_value" }
        it{ is_expected.to be false }
      end

      context "when the attribute satisfies the filter" do
        let(:filter){ "dependent_attribute_value" }
        it{ is_expected.to be true }
      end
    end
  end

  context "when the attribute has a symbol source" do
    let(:attribute_owner){ dependent_owner }
    include_examples "for an attribute property", :symbol_dependent
  end

  context "when the attribute has an array source" do
    let(:attribute_owner){ dependent_owner }
    include_examples "for an attribute property", :array_dependent
  end

  context "when the attribute has a hash source" do
    let(:attribute_owner){ dependent_owner.child }
    include_examples "for an attribute property", :hash_dependent
  end

  context "when the attribute has a mixed source" do
    let(:attribute_owner){ dependent_owner.child.child }
    include_examples "for an attribute property", :mixed_dependent
  end
end