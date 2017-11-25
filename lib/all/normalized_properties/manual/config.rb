module NormalizedProperties
  module Manual
    class Config < PropertyConfig
      def initialize(owner, name, type, config)
        super owner, name, Manual.const_get(type)
      end
    end
  end
end