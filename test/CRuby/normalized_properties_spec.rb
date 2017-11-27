describe NormalizedProperties do
  let(:model){ Class.new{ extend NormalizedProperties } }

  describe ".normalized_attribute" do
    subject{ model.normalized_attribute :name, config }

    context "when defining an attribute of an unknown type" do
      let(:config){ {type: 'Unknown'} }
      it{ is_expected.to raise_error NormalizedProperties::Error, "unknown property type \"Unknown\"" }
    end

    context "when defining an attribute of a known type" do
      let(:config){ {type: 'Manual'} }
      it{ is_expected.not_to raise_error }
    end
  end

  describe ".normalized_set" do
    subject{ model.normalized_set :name, config }

    context "when defining a set of an unknown type" do
      let(:config){ {type: 'Unknown'} }
      it{ is_expected.to raise_error NormalizedProperties::Error, "unknown property type \"Unknown\"" }
    end

    context "when defining a set of a known type" do
      context "when not providing an item model" do
        let(:config){ {type: 'Manual'} }
        it{ is_expected.to raise_error KeyError, "key not found: :item_model" }
      end

      context "when not providing an item model" do
        let(:config){ {type: 'Manual', item_model: 'Item'} }
        it{ is_expected.not_to raise_error }
      end
    end
  end

  describe ".property_config" do
    subject{ model.property_config name }

    context "when the property has been defined" do
      let(:name){ :name }
      before{ model.normalized_attribute name, type: 'Manual' }
      it{ is_expected.to have_attributes(owner: model, name: name) }
    end

    context "when the property is not known" do
      let(:name){ :name2 }
      it{ is_expected.to be nil }

      context "when a superclass knows the property" do
        let(:super_model){ Class.new{ extend NormalizedProperties } }
        let(:model){ Class.new(super_model) }
        before{ super_model.normalized_attribute name, type: 'Manual' }
        it{ is_expected.to have_attributes(owner: super_model, name: name) }
      end
    end
  end
end
