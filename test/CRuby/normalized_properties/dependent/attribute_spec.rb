describe NormalizedProperties::Dependent::Attribute do
  before do
    stub_const('AttributeOwner', Class.new{ extend NormalizedProperties })
  end

  let(:owner){ AttributeOwner.new }

  describe "an attribute with a simple value" do
    before do
      class AttributeOwner
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
          sources_filter: ->(filter){ {attribute: filter.sub("dependent_", "")} },
          value: ->(sources){ "dependent_#{sources[:attribute].value}" }

        normalized_attribute :array_dependent, type: 'Dependent',
          sources: [:attribute],
          sources_filter: ->(filter){ {attribute: filter.sub("dependent_", "")} },
          value: ->(sources){ "dependent_#{sources[:attribute].value}" }

        normalized_attribute :hash_dependent, type: 'Dependent',
          sources: {child: :attribute},
          sources_filter: ->(filter){ {child: {attribute: filter.sub("dependent_", "")}} },
          value: ->(sources){ "dependent_#{sources[:child][:attribute].value}" }

        normalized_attribute :mixed_dependent, type: 'Dependent',
          sources: {child: [child: :attribute]},
          sources_filter: ->(filter){ {child: {attribute: filter.sub("dependent_", "")}} },
          value: ->(sources){ "dependent_#{sources[:child][:child][:attribute].value}" }
      end
    end

    shared_examples "for an attribute property" do|property_name|
      subject(:dependent_attribute){ owner.property property_name }

      it{ is_expected.to have_attributes(owner: owner) }
      it{ is_expected.to have_attributes(name: property_name) }
      it{ is_expected.to have_attributes(to_s: "#{owner}##{property_name}") }
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
      let(:attribute_owner){ owner }
      include_examples "for an attribute property", :symbol_dependent
    end

    context "when the attribute has an array source" do
      let(:attribute_owner){ owner }
      include_examples "for an attribute property", :array_dependent
    end

    context "when the attribute has a hash source" do
      let(:attribute_owner){ owner.child }
      include_examples "for an attribute property", :hash_dependent
    end

    context "when the attribute has a mixed source" do
      let(:attribute_owner){ owner.child.child }
      include_examples "for an attribute property", :mixed_dependent
    end
  end

  describe "an attribute with a model instance as value" do
    before do
      stub_const('ManualObject', Class.new do
        extend NormalizedProperties

        def initialize(value)
          @value = value
        end

        alias id __id__
        normalized_attribute :id, type: 'Manual'

        attr_reader :value
        normalized_attribute :value, type: 'Manual'
      end)

      stub_const('DependentObject', Class.new do
        extend NormalizedProperties

        def initialize(object)
          @object = object
        end

        attr_reader :object
        normalized_attribute :object, type: 'Manual'

        def ==(other)
          @object == other&.object
        end
        alias eql? ==

        def hash
          @object.hash
        end
      end)
    end

    describe "an object dependent attribute" do
      subject(:dependent_attribute){ owner.property :object_dependent }

      before do
        class AttributeOwner
          attr_accessor :object
          normalized_attribute :object, type: 'Manual', item_model: 'ManualObject'

          normalized_attribute :object_dependent, type: 'Dependent', value_model: 'DependentObject',
            sources: :object,
            sources_filter: ->(filter){ {object: (filter.is_a? DependentObject) ? filter.object : filter} },
            value: ->(sources){ DependentObject.new sources[:object].value }
        end
      end

      let(:object) { ManualObject.new 'object' }
      before{ owner.object = object }

      it{ is_expected.to have_attributes(owner: owner) }
      it{ is_expected.to have_attributes(name: :object_dependent) }
      it{ is_expected.to have_attributes(to_s: "#{owner}#object_dependent") }
      it{ is_expected.to have_attributes(value: DependentObject.new(object)) }

      describe "watching a change" do
        subject do
          owner.object = changed_object
          owner.property(:object).changed!
        end

        let(:changed_object){ ManualObject.new 'changed_object' }

        before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
        let(:callback){ proc{} }

        before{ expect(callback).to receive(:call) }
        it{ is_expected.not_to raise_error }
        after{ expect(dependent_attribute.value).to eq DependentObject.new(changed_object) }
      end

      describe "#satisfies?" do
        subject{ dependent_attribute.satisfies? filter }

        context "when the filter is a hash with property sub filters" do
          context "when the set does not satisfy the filter" do
            let(:filter){ {value: "another_object"} }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ {value: 'object'} }
            it{ is_expected.to be true }
          end
        end

        context "when the filter is an item directly" do
          context "when the set does not satisfy the filter" do
            let(:filter){ DependentObject.new another_object }
            let(:another_object) { ManualObject.new 'another_object' }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ DependentObject.new object }
            it{ is_expected.to be true }
          end
        end
      end
    end

    describe "a set dependent attribute" do
      subject(:dependent_attribute){ owner.property :set_dependent }

      before do
        class AttributeOwner
          def initialize
            @set = []
          end

          attr_accessor :set
          normalized_set :set, type: 'Manual', item_model: 'ManualObject'

          normalized_attribute :set_dependent, type: 'Dependent', value_model: 'DependentObject',
            sources: :set,
            sources_filter: ->(filter){ {set: (filter.is_a? DependentObject) ? filter.object : filter} },
            value: ->(sources){ DependentObject.new sources[:set].value.find{ |item| item.value == 'item2' } },
            value_filter: ->(value){ {id: value.object.id} }
        end
      end

      let(:item1){ ManualObject.new 'item1' }
      let(:item2){ ManualObject.new 'item2' }
      let(:item3){ ManualObject.new 'item3' }
      before{ owner.set = [item1, item2, item3] }

      it{ is_expected.to have_attributes(owner: owner) }
      it{ is_expected.to have_attributes(name: :set_dependent) }
      it{ is_expected.to have_attributes(to_s: "#{owner}#set_dependent") }
      it{ is_expected.to have_attributes(value: DependentObject.new(item2)) }

      describe "watching a change" do
        def remove
          owner.set.delete item2
          owner.property(:set).removed! item2
        end

        def add
          owner.set.push item2
          owner.property(:set).added! item2
        end

        context "when the base item is removed from the set" do
          subject{ remove }
          before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
          let(:callback){ proc{} }

          before{ expect(callback).to receive(:call) }
          it{ is_expected.not_to raise_error }
          after{ expect(dependent_attribute.value).to eq nil }
        end

        context "when the base item is added the set" do
          before{ remove }
          subject{ add }
          before{ dependent_attribute.on(:changed){ |*args| callback.call *args } }
          let(:callback){ proc{} }

          before{ expect(callback).to receive(:call) }
          it{ is_expected.not_to raise_error }
          after{ expect(dependent_attribute.value).to eq DependentObject.new(item2) }
        end
      end

      describe "#satisfies?" do
        subject{ dependent_attribute.satisfies? filter }

        context "when the filter is a hash with property sub filters" do
          context "when the set does not satisfy the filter" do
            let(:filter){ {value: "item1"} }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ {value: 'item2'} }
            it{ is_expected.to be true }
          end
        end

        context "when the filter is an item directly" do
          context "when the set does not satisfy the filter" do
            let(:filter){ DependentObject.new(item1) }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ DependentObject.new(item2) }
            it{ is_expected.to be true }
          end
        end
      end
    end
  end
end