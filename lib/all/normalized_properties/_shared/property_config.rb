module NormalizedProperties
  class PropertyConfig
    def initialize(owner, name, namespace, type, config)
      @owner = owner
      @name = name
      @namespace = namespace
      @type = type
      @config = config
      @property_class = namespace.const_get type
    end

    attr_reader :owner, :name, :namespace, :type

    def to_property_for(owner)
      @property_class.new owner, self
    end
  end
end