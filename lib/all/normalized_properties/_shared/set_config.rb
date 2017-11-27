module NormalizedProperties
  class SetConfig < PropertyConfig
    def initialize(owner, name, namespace, config)
      super
      @item_model_name = config.fetch :item_model
    end

    def item_model
      @item_model ||= @owner.const_get @item_model_name
    end

    def to_property_for(owner)
      @namespace::Set.new owner, self
    end
  end
end