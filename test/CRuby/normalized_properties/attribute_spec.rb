describe NormalizedProperties::Attribute do
  before do
    stub_const('PropertyOwner', Class.new do
      extend NormalizedProperties

      attr_accessor :attribute
      normalized_attribute :attribute, type: 'Manual'
    end)
  end

  describe "#satisfies?" do
    subject{ attribute.satisfies? filter }

    let(:attribute){ owner.property :attribute }
    let(:owner){ PropertyOwner.new }

    before do
      PropertyOwner.class_eval do
        alias id __id__
        normalized_attribute :id, type: 'Manual'

        attr_accessor :attribute
        normalized_attribute :attribute, type: 'Manual'

        attr_accessor :set
        normalized_set :set, type: 'Manual'
      end
    end

    context "when the attribute has a simple value" do
      before{ owner.attribute = 'attribute_value' }

      context "when the attribute value matches the filter value" do
        let(:filter){ 'attribute_value' }
        it{ is_expected.to be true }
      end

      context "when the attribute value does not match the filter value" do
        let(:filter){ nil }
        it{ is_expected.to be false }
      end
    end

    context "when the attribute value is an object having normalized properties" do
      let(:association) do
        PropertyOwner.new.tap do |association|
          association.attribute = 'attribute_value'
        end
      end
      before{ owner.attribute = association }

      context "when the filter is an arbitrary value" do
        let(:filter){ 'arbitrary' }
        it{ is_expected.to be false }

        context "when no object is associated" do
          let(:association){ nil }
          it{ is_expected.to be false }
        end
      end

      context "when filtering by the mere existence of an object" do
        let(:filter){ true }
        it{ is_expected.to be true }

        context "when no object is associated" do
          let(:association){ nil }
          it{ is_expected.to be false }
        end
      end

      context "when filtering by the lack of an object" do
        let(:filter){ nil }
        it{ is_expected.to be false }

        context "when no object is associated" do
          let(:association){ nil }
          it{ is_expected.to be true }
        end
      end

      context "when filtering directly by an object" do
        context "when it is the same object" do
          let(:filter){ association }
          it{ is_expected.to be true }

          context "when no object is associated" do
            before{ owner.attribute = nil }
            it{ is_expected.to be false }
          end
        end

        context "when it is another object" do
          let(:filter){ another_object }
          let(:another_object){ PropertyOwner.new }
          it{ is_expected.to be false }

          context "when no object is associated" do
            let(:association){ nil }
            it{ is_expected.to be false }
          end
        end
      end

      context "when filtering by the properties of the object" do
        context "when no properties are given" do
          let(:filter){ {} }
          it{ is_expected.to be true }

          context "when no object is associated" do
            let(:association){ nil }
            it{ is_expected.to be false }
          end
        end

        context "when a property does not exist" do
          let(:filter){ {unknown: 'value'} }
          it{ is_expected.to raise_error NormalizedProperties::Error, "property PropertyOwner#unknown does not exist" }

          context "when no object is associated" do
            let(:association){ nil }
            it{ is_expected.to be false }
          end
        end

        context "when a property does not satisfy the filter" do
          let(:filter){ {attribute: 'another_value'} }
          it{ is_expected.to be false }

          context "when no object is associated" do
            let(:association){ nil }
            it{ is_expected.to be false }
          end
        end

        context "when a property satisfies the filter" do
          let(:filter){ {attribute: 'attribute_value'} }
          it{ is_expected.to be true }

          context "when no object is associated" do
            let(:association){ nil }
            it{ is_expected.to be false }
          end
        end
      end
    end
  end
end