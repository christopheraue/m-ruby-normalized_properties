module NormalizedProperties
  class PropertyConfig
    def initialize(owner, name, options)
      @owner = owner
      @name = name
      @property_class = options.fetch :property_class
      @filter_mapper = options.fetch :filter
    end

    attr_reader :owner, :name, :filter_mapper

    def to_property_for(owner)
      @property_class.new owner, self
    end
  end
end