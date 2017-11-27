module NormalizedProperties
  class AttributeConfig < PropertyConfig
    def initialize(owner, name, namespace, config)
      super
      @value_model_name = config[:value_model]
    end

    def value_model
      return unless @value_model_name
      @value_model ||= @owner.const_get @value_model_name
    end

    def to_property_for(owner)
      @namespace::Attribute.new owner, self
    end
  end
end