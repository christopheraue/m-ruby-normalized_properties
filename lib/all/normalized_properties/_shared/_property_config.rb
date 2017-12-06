module NormalizedProperties
  class PropertyConfig
    def initialize(owner, name, namespace, config)
      @owner = owner
      @name = name
      @namespace = namespace
      @model_name = config[:model]
      @config = config
    end

    attr_reader :owner, :name, :namespace

    def model
      return unless @model_name
      @model ||= @owner.const_get @model_name
    end

    def resolve_filter(filter)
      {@name => filter}
    end
  end
end