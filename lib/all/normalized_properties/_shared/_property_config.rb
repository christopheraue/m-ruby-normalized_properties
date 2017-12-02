module NormalizedProperties
  class PropertyConfig
    def initialize(owner, name, namespace, config)
      @owner = owner
      @name = name
      @namespace = namespace
      @config = config
    end

    attr_reader :owner, :name, :namespace

    def resolve_filter(filter)
      {@name => filter}
    end
  end
end