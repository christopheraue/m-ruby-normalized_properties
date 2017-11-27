module NormalizedProperties
  class AttributeConfig < PropertyConfig
    def initialize(owner, name, namespace, type, config)
      @owner = owner
      @name = name
      @namespace = namespace
      @type = type
      @config = config
      @property_class = namespace.const_get type
    end
  end
end