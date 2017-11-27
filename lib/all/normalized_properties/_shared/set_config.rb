module NormalizedProperties
  class SetConfig < PropertyConfig
    def to_property_for(owner)
      @namespace::Set.new owner, self
    end
  end
end