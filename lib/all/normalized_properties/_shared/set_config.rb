module NormalizedProperties
  class SetConfig < PropertyConfig
    def initialize(owner, name, namespace, config)
      super
      @model_name = config[:item_model]
    end

    def model
      return unless @model_name
      @model ||= @owner.const_get @model_name
    end

    def to_property_for(owner)
      @namespace::Set.new owner, self
    end
  end
end