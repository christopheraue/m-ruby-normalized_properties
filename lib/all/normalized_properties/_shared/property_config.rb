module NormalizedProperties
  class PropertyConfig
    def initialize(owner, name, type)
      @owner = owner
      @name = name
      @property_class = type
    end

    attr_reader :owner, :name

    def to_property_for(owner)
      @property_class.new owner, self
    end
  end
end