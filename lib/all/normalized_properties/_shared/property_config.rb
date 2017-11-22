module NormalizedProperties
  class PropertyConfig
    def initialize(owner, name, options)
      @owner = owner
      @name = name
      @property_class = options.fetch :property_class
      @filter_mapper = options.fetch :filter
      @model_name = options.fetch :model
    end

    attr_reader :owner, :name, :filter_mapper

    def model
      @model ||= if not @model_name
                   nil
                 elsif @owner.const_defined? @model_name
                   @owner.const_get @model_name
                 else
                   Object.const_get @model_name
                 end
    end

    def to_property_for(owner)
      @property_class.new owner, self
    end
  end
end