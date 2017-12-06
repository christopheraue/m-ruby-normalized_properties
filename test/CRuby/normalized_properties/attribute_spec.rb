describe NormalizedProperties::Attribute do
  before do
    stub_const('PropertyOwner', Class.new do
      extend NormalizedProperties

      attr_accessor :attribute
      normalized_attribute :attribute, type: 'Manual'

      attr_accessor :attribute2
      normalized_attribute :attribute2, type: 'Manual'

      attr_accessor :association
      normalized_attribute :association, type: 'Manual', model: 'PropertyOwner'
    end)
  end

  subject(:attribute){ owner.property :attribute }
  let(:owner){ PropertyOwner.new }

  describe "#model" do
    context "when it's a simple attribute" do
      subject{ owner.property :attribute }
      it{ is_expected.to have_attributes(model: nil) }
    end

    context "when it's an association attribute" do
      subject{ owner.property :association }
      it{ is_expected.to have_attributes(model: PropertyOwner) }
    end
  end

  describe "#satisfies?" do
    subject{ attribute.satisfies? filter }

    before do
      PropertyOwner.class_eval do
        attr_accessor :attribute
        normalized_attribute :attribute, type: 'Manual'
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
      let(:attribute){ owner.property :association }
      let(:association) do
        PropertyOwner.new.tap do |association|
          association.attribute = 'attribute_value'
          association.attribute2 = 'attribute2_value'
        end
      end
      before{ owner.association = association }

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
            before{ owner.association = nil }
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

      context "when filtering by a combination of filters" do
        context "when all filters must by satisfied" do
          let(:filter){ NP.and filter1, filter2 }

          context "when the property satisfies the filter" do
            let(:filter1){ {attribute: 'attribute_value'} }
            let(:filter2){ {attribute2: 'attribute2_value'} }
            it{ is_expected.to be true }
          end

          context "when the property does not satisfy the filter" do
            let(:filter1){ {attribute: 'another_value'} }
            let(:filter2){ {attribute2: 'attribute2_value'} }
            it{ is_expected.to be false }
          end
        end

        context "when some filters must by satisfied" do
          let(:filter){ NP.or filter1, filter2 }

          context "when the property satisfies the filter" do
            let(:filter1){ {attribute: 'another_value'} }
            let(:filter2){ {attribute2: 'attribute2_value'} }
            it{ is_expected.to be true }
          end

          context "when the property does not satisfy the filter" do
            let(:filter1){ {attribute: 'another_value'} }
            let(:filter2){ {attribute2: 'another_value'} }
            it{ is_expected.to be false }
          end
        end

        context "when none of the given filters must by satisfied" do
          let(:filter){ NP.not filter1, filter2 }

          context "when the property satisfies the filter" do
            let(:filter1){ {attribute: 'another_value'} }
            let(:filter2){ {attribute2: 'another_value'} }
            it{ is_expected.to be true }
          end

          context "when the property does not satisfy the filter" do
            let(:filter1){ {attribute: 'attribute_value'} }
            let(:filter2){ {attribute2: 'another_value'} }
            it{ is_expected.to be false }
          end
        end
      end
    end
  end
end