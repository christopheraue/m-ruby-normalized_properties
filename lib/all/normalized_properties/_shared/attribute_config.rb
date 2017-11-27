module NormalizedProperties
  class AttributeConfig < PropertyConfig
    def to_property_for(owner)
      @namespace::Attribute.new owner, self
    end
  end
end