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
        value: ->(sources){ "symbol_dependent_#{sources[:attribute].value}" },
        filter: ->(filter){ {attribute: filter.sub("symbol_dependent_", "")} }

      normalized_attribute :array_dependent, type: 'Dependent',
        sources: [:attribute],
        value: ->(sources){ "array_dependent_#{sources[:attribute].value}" },
        filter: ->(filter){ {attribute: filter.sub("array_dependent_", "")} }

      normalized_attribute :hash_dependent, type: 'Dependent',
        sources: {child: :attribute},
        value: ->(sources){ "hash_dependent_#{sources[:child][:attribute].value}" },
        filter: ->(filter){ {child: {attribute: filter.sub("hash_dependent_", "")}} }

      normalized_attribute :mixed_dependent, type: 'Dependent',
        sources: {child: [child: :attribute]},
        value: ->(sources){ "mixed_dependent_#{sources[:child][:child][:attribute].value}" },
        filter: ->(filter){ {child: {attribute: filter.sub("mixed_dependent_", "")}} }
    end)
  end
  
  let(:owner){ AttributeOwner.new }

  context "when the attribute has a symbol source" do
    subject(:dependent_attribute){ owner.property :symbol_dependent }

    it{ is_expected.to have_attributes(owner: owner) }
    it{ is_expected.to have_attributes(name: :symbol_dependent) }
    it{ is_expected.to have_attributes(to_s: "#{owner}#symbol_dependent") }
    it{ is_expected.to have_attributes(value: 'symbol_dependent_attribute_value') }

    describe "watching a change" do
      subject{ owner.attribute = 'changed_value' }

      before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
      let(:callback){ proc{} }

      before{ expect(callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(dependent_attribute.value).to eq 'symbol_dependent_changed_value' }
    end

    describe "#satisfies?" do
      subject{ dependent_attribute.satisfies? filter }

      context "when the attribute does not satisfy the filter" do
        let(:filter){ "another_value" }
        it{ is_expected.to be false }
      end

      context "when the attribute satisfies the filter" do
        let(:filter){ "symbol_dependent_attribute_value" }
        it{ is_expected.to be true }
      end
    end
  end

  context "when the attribute has an array source" do
    subject(:dependent_attribute){ owner.property :array_dependent }

    it{ is_expected.to have_attributes(owner: owner) }
    it{ is_expected.to have_attributes(name: :array_dependent) }
    it{ is_expected.to have_attributes(to_s: "#{owner}#array_dependent") }
    it{ is_expected.to have_attributes(value: 'array_dependent_attribute_value') }

    describe "watching a change" do
      subject{ owner.attribute = 'changed_value' }

      before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
      let(:callback){ proc{} }

      before{ expect(callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(dependent_attribute.value).to eq 'array_dependent_changed_value' }
    end

    describe "#satisfies?" do
      subject{ dependent_attribute.satisfies? filter }

      context "when the attribute does not satisfy the filter" do
        let(:filter){ "another_value" }
        it{ is_expected.to be false }
      end

      context "when the attribute satisfies the filter" do
        let(:filter){ "array_dependent_attribute_value" }
        it{ is_expected.to be true }
      end
    end
  end

  context "when the attribute has a hash source" do
    subject(:dependent_attribute){ owner.property :hash_dependent }

    it{ is_expected.to have_attributes(owner: owner) }
    it{ is_expected.to have_attributes(name: :hash_dependent) }
    it{ is_expected.to have_attributes(to_s: "#{owner}#hash_dependent") }
    it{ is_expected.to have_attributes(value: 'hash_dependent_attribute_value') }

    describe "watching a change" do
      subject{ owner.child.attribute = 'changed_value' }

      before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
      let(:callback){ proc{} }

      before{ expect(callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(dependent_attribute.value).to eq 'hash_dependent_changed_value' }
    end

    describe "#satisfies?" do
      subject{ dependent_attribute.satisfies? filter }

      context "when the attribute does not satisfy the filter" do
        let(:filter){ "another_value" }
        it{ is_expected.to be false }
      end

      context "when the attribute satisfies the filter" do
        let(:filter){ "hash_dependent_attribute_value" }
        it{ is_expected.to be true }
      end
    end
  end

  context "when the attribute has a mixed source" do
    subject(:dependent_attribute){ owner.property :mixed_dependent }

    it{ is_expected.to have_attributes(owner: owner) }
    it{ is_expected.to have_attributes(name: :mixed_dependent) }
    it{ is_expected.to have_attributes(to_s: "#{owner}#mixed_dependent") }
    it{ is_expected.to have_attributes(value: 'mixed_dependent_attribute_value') }

    describe "watching a change" do
      subject{ owner.child.child.attribute = 'changed_value' }

      before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
      let(:callback){ proc{} }

      before{ expect(callback).to receive(:call) }
      it{ is_expected.not_to raise_error }
      after{ expect(dependent_attribute.value).to eq 'mixed_dependent_changed_value' }
    end

    describe "#satisfies?" do
      subject{ dependent_attribute.satisfies? filter }

      context "when the attribute does not satisfy the filter" do
        let(:filter){ "another_value" }
        it{ is_expected.to be false }
      end

      context "when the attribute satisfies the filter" do
        let(:filter){ "mixed_dependent_attribute_value" }
        it{ is_expected.to be true }
      end
    end
  end
end