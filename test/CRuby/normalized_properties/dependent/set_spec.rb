describe NormalizedProperties::Dependent::Set do
  before do
    stub_const('SetOwner', Class.new do
      extend NormalizedProperties

      attr_accessor :set
      normalized_set :set, type: 'Manual', item_model: 'Item'

      attr_accessor :no_model_set
      normalized_set :no_model_set, type: 'Manual'
    end)
  end

  let(:owner){ SetOwner.new }
  
  before do
    stub_const('Item', Class.new do
      extend NormalizedProperties

      attr_accessor :attribute
      normalized_attribute :attribute, type: 'Manual'

      attr_accessor :association
      normalized_attribute :association, type: 'Manual', value_model: 'ItemProperty'

      attr_accessor :set
      normalized_set :set, type: 'Manual', item_model: 'ItemProperty'
    end)

    stub_const('ItemProperty', Class.new do
      extend NormalizedProperties

      def initialize(content)
        @content = content
      end

      attr_reader :content
      normalized_attribute :content, type: 'Manual'
    end)

    stub_const('DependentItem', Class.new do
      extend NormalizedProperties

      def initialize(item)
        @item = item
      end
      attr_reader :item
      normalized_attribute :item, type: 'Manual', value_model: 'Item'

      normalized_attribute :attribute, type: 'Dependent',
        sources: {item: :attribute},
        sources_filter: ->(filter){ {item: {attribute: filter}} },
        value: ->(sources){ sources[:item][:attribute].value }

      def association
        property(:association).value
      end
      normalized_attribute :association, type: 'Dependent', value_model: 'ItemProperty',
        sources: {item: :association},
        sources_filter: ->(filter){ {item: {association: filter}} },
        value: ->(sources){ sources[:item][:association].value }

      def set
        property(:set).value
      end
      normalized_set :set, type: 'Dependent', item_model: 'ItemProperty',
        sources: {item: :set},
        sources_filter: ->(filter){ {item: {set: filter}} },
        value: ->(sources){ sources[:item][:set].value }

      def to_filter
        {__model_id__: item.property(:__model_id__).value}
      end

      def ==(other)
        @item == other.item
      end
      alias eql? ==

      def hash
        @item.hash
      end
    end)
  end

  describe "a set with simple values as items" do
    subject(:dependent_set){ owner.property :dependent_set }

    shared_examples "for a set property" do
      before{ set_owner.no_model_set = %w(item1 item2 item3) }

      it{ is_expected.to have_attributes(owner: owner) }
      it{ is_expected.to have_attributes(name: :dependent_set) }
      it{ is_expected.to have_attributes(to_s: "#{owner}#dependent_set") }

      describe "#filter" do
        subject{ dependent_set.filter }
        let(:dependent_set){ owner.property(:dependent_set).where NP.or('item1', 'item2') }
        it{ is_expected.to have_attributes(op: :and, parts: [have_attributes(op: :or, parts: %w(item1 item2))]) }
      end

      describe "#dependencies_resolved_filter" do
        subject{ dependent_set.dependencies_resolved_filter }
        let(:dependent_set){ owner.property(:dependent_set).where NP.or('item1', 'item2') }
        it{ is_expected.to have_attributes(op: :and, parts: [have_attributes(op: :or, parts: %w(item1 item2))]) }
      end

      describe "#value" do
        subject{ dependent_set.value }

        context "when the set has not been filtered" do
          it{ is_expected.to eq %w(item1 item2 item3) }
        end

        context "when the set has been filtered" do
          let(:dependent_set){ owner.property(:dependent_set).where filter }

          context "when the filter is nil" do
            let(:filter){ nil }
            it{ is_expected.to eq %w(item1 item2 item3) }
          end

          context "when no item matches the filter" do
            let(:filter){ 'no_item' }
            it{ is_expected.to eq [] }
          end

          context "when one item matches the filter" do
            let(:filter){ 'item2' }
            it{ is_expected.to eq %w(item2) }
          end

          context "when multiple items match the filter" do
            let(:filter){ NP.or 'item1', 'item2' }
            it{ is_expected.to eq %w(item1 item2) }
          end
        end
      end

      describe "#satisfies?" do
        subject{ dependent_set.satisfies? filter }

        context "when the filter is a hash with property sub filters" do
          context "when the set does not satisfy the filter" do
            let(:filter){ 'no_item' }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ 'item2' }
            it{ is_expected.to be true }
          end
        end
      end

      describe "watching the addition of an item" do
        subject do
          set_owner.no_model_set.push 'item4'
          set_owner.property(:no_model_set).added! 'item4'
        end

        before{ dependent_set.on(:added){ |*args| addition_callback.call *args } }
        before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
        let(:addition_callback){ proc{} }
        let(:change_callback){ proc{} }

        before{ expect(addition_callback).to receive(:call).with('item4') }
        before{ expect(change_callback).to receive(:call) }
        it{ is_expected.not_to raise_error }
        after{ expect(dependent_set.value).to eq %w(item1 item2 item3 item4)}
      end

      describe "watching the removal of an item" do
        subject do
          set_owner.no_model_set.delete 'item2'
          set_owner.property(:no_model_set).removed! 'item2'
        end

        before{ dependent_set.on(:removed){ |*args| removal_callback.call *args } }
        before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
        let(:removal_callback){ proc{} }
        let(:change_callback){ proc{} }

        before{ expect(removal_callback).to receive(:call).with('item2') }
        before{ expect(change_callback).to receive(:call) }
        it{ is_expected.not_to raise_error }
        after{ expect(dependent_set.value).to eq %w(item1 item3)}
      end
    end

    context "when the set has a symbol source" do
      before do
        class SetOwner
          normalized_set :dependent_set, type: 'Dependent',
            sources: :no_model_set,
            sources_filter: ->(filter){ {no_model_set: filter} },
            value: ->(sources){ sources[:no_model_set].value }
        end
      end

      let(:set_owner){ owner }
      include_examples "for a set property"
    end

    context "when the set has an array source" do
      before do
        class SetOwner
          normalized_set :dependent_set, type: 'Dependent',
            sources: [:no_model_set],
            sources_filter: ->(filter){ {no_model_set: filter} },
            value: ->(sources){ sources[:no_model_set].value }
        end
      end

      let(:set_owner){ owner }
      include_examples "for a set property"
    end

    context "when the set has a hash source" do
      before do
        class SetOwner
          def child
            @child ||= self.class.new
          end
          normalized_attribute :child, type: 'Manual', value_model: 'SetOwner'

          normalized_set :dependent_set, type: 'Dependent',
            sources: {child: :no_model_set},
            sources_filter: ->(filter){ {child: {no_model_set: filter}} },
            value: ->(sources){ sources[:child][:no_model_set].value }
        end
      end

      let(:set_owner){ owner.child }
      include_examples "for a set property"
    end

    context "when the set has a mixed source" do
      before do
        class SetOwner
          def child
            @child ||= self.class.new
          end
          normalized_attribute :child, type: 'Manual', value_model: 'SetOwner'

          normalized_set :dependent_set, type: 'Dependent',
            sources: {child: [child: :no_model_set]},
            sources_filter: ->(filter){ {child: {child: {no_model_set: filter}}} },
            value: ->(sources){ sources[:child][:child][:no_model_set].value }
        end
      end

      let(:set_owner){ owner.child.child }
      include_examples "for a set property"
    end
  end

  describe "a set with model instances as items" do
    subject(:dependent_set){ owner.property :dependent_set }

    shared_examples "for a set property" do
      let(:item1) do
        Item.new.tap do |item|
          item.attribute = 'attribute1'
          item.association = ItemProperty.new('association1')
          item.set = [ItemProperty.new('setitem1')]
        end
      end
      let(:dependent_item1){ DependentItem.new item1 }

      let(:item2) do
        Item.new.tap do |item|
          item.attribute = 'attribute2'
          item.association = nil
          item.set = [ItemProperty.new('setitem2')]
        end
      end
      let(:dependent_item2){ DependentItem.new item2 }

      let(:item3) do
        Item.new.tap do |item|
          item.attribute = 'attribute1'
          item.association = ItemProperty.new('association3')
          item.set = []
        end
      end
      let(:dependent_item3){ DependentItem.new item3 }

      let(:item4){ Item.new }
      let(:dependent_item4){ DependentItem.new item4 }

      before{ set_owner.set = [item1, item2, item3] }

      it{ is_expected.to have_attributes(owner: owner) }
      it{ is_expected.to have_attributes(name: :dependent_set) }
      it{ is_expected.to have_attributes(to_s: "#{owner}#dependent_set") }

      describe "#filter" do
        subject{ dependent_set.filter }
        let(:dependent_set){ owner.property(:dependent_set).where\
          NP.and({attribute: 'attribute1'}, {association: true}) }
        it{ is_expected.to have_attributes(op: :and, parts:
          [have_attributes(op: :and, parts: [{attribute: 'attribute1'}, {association: true}])]) }
      end

      describe "#dependencies_resolved_filter" do
        subject{ dependent_set.dependencies_resolved_filter }
        let(:dependent_set){ owner.property(:dependent_set).where\
          NP.and({attribute: 'attribute1'}, {association: true}) }
        it{ is_expected.to have_attributes(op: :and, parts:
          [have_attributes(op: :and, parts: [{item: {attribute: 'attribute1'}}, {item: {association: true}}])]) }
      end

      describe "#value" do
        subject{ dependent_set.value }

        context "when the set has not been filtered" do
          it{ is_expected.to eq [dependent_item1, dependent_item2, dependent_item3] }
        end

        context "when the set has been filtered" do
          let(:dependent_set){ owner.property(:dependent_set).where filter }

          context "when the filter is empty" do
            let(:filter){ {} }
            it{ is_expected.to eq [dependent_item1, dependent_item2, dependent_item3] }
          end

          context "when filtering by an unknown property" do
            let(:filter){ {unknown: 'value'} }
            it{ is_expected.to raise_error NormalizedProperties::Error, "property DependentItem#unknown does not exist" }
          end

          context "when filtering by an attribute property of the set items" do
            context "when no item matches the filter" do
              let(:filter){ {attribute: 'no_item'} }
              it{ is_expected.to eq [] }
            end

            context "when one item matches the filter" do
              let(:filter){ {attribute: 'attribute2'} }
              it{ is_expected.to eq [dependent_item2] }
            end

            context "when multiple items match the filter" do
              let(:filter){ {attribute: 'attribute1'} }
              it{ is_expected.to eq [dependent_item1, dependent_item3] }
            end
          end

          context "when filtering by an association property of the set items" do
            context "when filtering the items merely by having an association" do
              let(:filter){ {association: true} }
              it{ is_expected.to eq [dependent_item1, dependent_item3] }
            end

            context "when filtering the items by having no association" do
              let(:filter){ {association: nil} }
              it{ is_expected.to eq [dependent_item2] }
            end

            context "when filtering the items by the properties of their associations" do
              let(:filter){ {association: {content: 'association1'}} }
              it{ is_expected.to eq [dependent_item1] }
            end

            context "when filtering the items by a directly given association" do
              let(:filter){ {association: dependent_item3.association} }
              it{ is_expected.to eq [dependent_item3] }
            end

            context "when filtering the items by an invalid filter" do
              let(:filter){ {association: :symbol} }
              it{ is_expected.to eq [] }
            end
          end

          context "when filtering by a set property of the set items" do
            context "when filtering the items by its subset having items" do
              let(:filter){ {set: true} }
              it{ is_expected.to eq [dependent_item1, dependent_item2] }
            end

            context "when filtering the items by its subset having no items" do
              let(:filter){ {set: false} }
              it{ is_expected.to eq [dependent_item3] }
            end

            context "when filtering the items by the properties of their associations" do
              let(:filter){ {set: {content: 'setitem1'}} }
              it{ is_expected.to eq [dependent_item1] }
            end

            context "when filtering the items by a directly given association" do
              let(:filter){ {set: dependent_item2.set.first} }
              it{ is_expected.to eq [dependent_item2] }
            end

            context "when filtering the items by an invalid filter" do
              let(:filter){ {set: :symbol} }
              it{ is_expected.to eq [] }
            end
          end
        end
      end

      describe "#satisfies?" do
        subject{ dependent_set.satisfies? filter }

        context "when the filter is a hash with property sub filters" do
          context "when the set does not satisfy the filter" do
            let(:filter){ {attribute: "another value"} }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ {attribute: 'attribute1'} }
            it{ is_expected.to be true }
          end
        end

        context "when the filter is an item directly" do
          context "when the set does not satisfy the filter" do
            let(:filter){ dependent_item4 }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ dependent_item1 }
            it{ is_expected.to be true }
          end
        end
      end

      describe "watching the addition of an item" do
        subject do
          set_owner.set.push item4
          set_owner.property(:set).added! item4
        end

        before{ dependent_set.on(:added){ |*args| addition_callback.call *args } }
        before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
        let(:addition_callback){ proc{} }
        let(:change_callback){ proc{} }

        before{ expect(addition_callback).to receive(:call).with(dependent_item4) }
        before{ expect(change_callback).to receive(:call) }
        it{ is_expected.not_to raise_error }
        after{ expect(dependent_set.value).to eq [dependent_item1, dependent_item2, dependent_item3,
          dependent_item4] }
      end

      describe "watching the removal of an item" do
        subject do
          set_owner.set.delete item2
          set_owner.property(:set).removed! item2
        end

        before{ dependent_set.on(:removed){ |*args| removal_callback.call *args } }
        before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
        let(:removal_callback){ proc{} }
        let(:change_callback){ proc{} }

        before{ expect(removal_callback).to receive(:call).with(dependent_item2) }
        before{ expect(change_callback).to receive(:call) }
        it{ is_expected.not_to raise_error }
        after{ expect(dependent_set.value).to eq [dependent_item1, dependent_item3] }
      end
    end

    context "when the set has a symbol source" do
      before do
        class SetOwner
          normalized_set :dependent_set, type: 'Dependent', item_model: 'DependentItem',
            sources: :set,
            sources_filter: ->(filter){ {set: filter} },
            value: ->(sources){ sources[:set].value.map{ |item| DependentItem.new item } }
        end
      end

      let(:set_owner){ owner }
      include_examples "for a set property"
    end

    context "when the set has an array source" do
      before do
        class SetOwner
          normalized_set :dependent_set, type: 'Dependent', item_model: 'DependentItem',
            sources: [:set],
            sources_filter: ->(filter){ {set: filter} },
            value: ->(sources){ sources[:set].value.map{ |item| DependentItem.new item } }
        end
      end

      let(:set_owner){ owner }
      include_examples "for a set property"
    end

    context "when the set has a hash source" do
      before do
        class SetOwner
          def child
            @child ||= self.class.new
          end
          normalized_attribute :child, type: 'Manual', value_model: 'SetOwner'

          normalized_set :dependent_set, type: 'Dependent', item_model: 'DependentItem',
            sources: {child: :set},
            sources_filter: ->(filter){ {child: {set: filter}} },
            value: ->(sources){ sources[:child][:set].value.map{ |item| DependentItem.new item } }
        end
      end

      let(:set_owner){ owner.child }
      include_examples "for a set property"
    end

    context "when the set has a mixed source" do
      before do
        class SetOwner
          def child
            @child ||= self.class.new
          end
          normalized_attribute :child, type: 'Manual', value_model: 'SetOwner'

          normalized_set :dependent_set, type: 'Dependent', item_model: 'DependentItem',
            sources: {child: [child: :set]},
            sources_filter: ->(filter){ {child: {child: {set: filter}}} },
            value: ->(sources){ sources[:child][:child][:set].value.map{ |item| DependentItem.new item } }
        end
      end

      let(:set_owner){ owner.child.child }
      include_examples "for a set property"
    end

    context "when the set consists of a subset of the set it depends on" do
      subject(:dependent_set){ owner.property :set_dependent }

      before do
        class SetOwner
          normalized_set :set_dependent, type: 'Dependent', item_model: 'DependentItem',
            sources: :set,
            sources_filter: ->(filter){ {set: filter} },
            value: ->(sources){ sources[:set].value.select{ |item| item.attribute == 'odd' }.map{ |item| DependentItem.new item } },
            value_filter: ->(value){ {__model_id__: (NP.or *value.map(&:item).map(&:__model_id__))} }
        end
      end

      let(:item1){ Item.new.tap{ |item| item.attribute = 'odd' } }
      let(:item2){ Item.new.tap{ |item| item.attribute = 'even' } }
      let(:item3){ Item.new.tap{ |item| item.attribute = 'odd' } }
      let(:item5){ Item.new.tap{ |item| item.attribute = 'odd' } }
      let(:dependent_item1){ DependentItem.new item1 }
      let(:dependent_item2){ DependentItem.new item2 }
      let(:dependent_item3){ DependentItem.new item3 }
      let(:dependent_item5){ DependentItem.new item5 }
      before{ owner.set = [item1, item2, item3] }

      it{ is_expected.to have_attributes(owner: owner) }
      it{ is_expected.to have_attributes(name: :set_dependent) }
      it{ is_expected.to have_attributes(to_s: "#{owner}#set_dependent") }
      it{ is_expected.to have_attributes(value: [dependent_item1, dependent_item3]) }

      describe "watching the addition of an item" do
        subject do
          owner.set.push item5
          owner.property(:set).added! item5
        end

        before{ dependent_set.on(:added){ |*args| addition_callback.call *args } }
        before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
        let(:addition_callback){ proc{} }
        let(:change_callback){ proc{} }

        before{ expect(addition_callback).to receive(:call).with(dependent_item5) }
        before{ expect(change_callback).to receive(:call) }
        it{ is_expected.not_to raise_error }
        after{ expect(dependent_set.value).to eq [dependent_item1, dependent_item3, dependent_item5] }
      end

      describe "watching the removal of an item" do
        subject do
          owner.set.delete item1
          owner.property(:set).removed! item1
        end

        before{ dependent_set.on(:removed){ |*args| removal_callback.call *args } }
        before{ dependent_set.on(:changed){ |*args| change_callback.call *args } }
        let(:removal_callback){ proc{} }
        let(:change_callback){ proc{} }

        before{ expect(removal_callback).to receive(:call).with(dependent_item1) }
        before{ expect(change_callback).to receive(:call) }
        it{ is_expected.not_to raise_error }
        after{ expect(dependent_set.value).to eq [dependent_item3] }
      end

      describe "#satisfies?" do
        subject{ dependent_set.satisfies? filter }

        context "when the filter is a hash with property sub filters" do
          context "when the set does not satisfy the filter" do
            let(:filter){ {attribute: "even"} }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ {attribute: 'odd'} }
            it{ is_expected.to be true }
          end
        end

        context "when the filter is an item directly" do
          context "when the set does not satisfy the filter" do
            let(:filter){ dependent_item2 }
            it{ is_expected.to be false }
          end

          context "when the set satisfies the filter" do
            let(:filter){ dependent_item1 }
            it{ is_expected.to be true }
          end
        end
      end
    end

    describe "filtering a set by nested dependent properties" do
      before do
        class Item
          normalized_attribute :dependent_attribute, type: 'Dependent', value_model: 'DependentItem',
            sources: :attribute,
            sources_filter: ->(filter){ {attribute: filter} },
            value: ->(sources){ DependentItem.new sources[:attribute].value }

          normalized_attribute :dependent_dependent_attribute, type: 'Dependent', item_model: 'ItemProperty',
            sources: :dependent_attribute,
            sources_filter: ->(filter){ {dependent_attribute: filter} },
            value: ->(sources){ sources[:dependent_attribute].value }
        end
      end

      let(:item1){ Item.new.tap{ |item| item.attribute = 'item1' } }
      let(:item2){ Item.new.tap{ |item| item.attribute = 'item2' } }
      let(:item3){ Item.new.tap{ |item| item.attribute = 'item3' } }
      before{ owner.set = [item1, item2, item3] }

      context "when the set has not been filtered" do
        subject{ owner.property :set }
        it{ is_expected.to have_attributes filter: have_attributes(parts: []) }
        it{ is_expected.to have_attributes value: [item1, item2, item3] }
      end

      context "when the set has been filtered" do
        subject{ owner.property(:set).where filter }

        context "when filtering by a dependent property" do
          let(:filter){ {dependent_attribute: 'item2'} }
          it{ is_expected.to have_attributes filter: have_attributes(parts: [{dependent_attribute: 'item2'}]) }
          it{ is_expected.to have_attributes dependencies_resolved_filter: have_attributes(parts: [{attribute: 'item2'}]) }
          it{ is_expected.to have_attributes value: [item2] }
        end

        context "when filtering by a dependent property depending on another dependent property" do
          let(:filter){ {dependent_dependent_attribute: 'item2'} }
          it{ is_expected.to have_attributes filter: have_attributes(parts: [{dependent_dependent_attribute: 'item2'}]) }
          it{ is_expected.to have_attributes dependencies_resolved_filter: have_attributes(parts: [{attribute: 'item2'}]) }
          it{ is_expected.to have_attributes value: [item2] }
        end
      end
    end
  end
end