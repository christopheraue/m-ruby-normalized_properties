module NormalizedProperties
  class PropertyConfig
    def initialize(owner, name, options)
      @owner = owner
      @name = name
      @property_class = options.fetch :property_class
      @filter_mapper = (options[:filter] or ->(filter_value){ {name => filter_value} })
      @model_name = options[:model_name]
    end

    attr_reader :name, :filter_mapper

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