module WatchableProperties
  module Manual
    class Config < PropertyConfig
      def initialize(owner, name, type, config)
        super owner, name,
          property_class: Manual.const_get(type),
          filter: config[:filter],
          model_name: config[:model]
      end
    end
  end
end