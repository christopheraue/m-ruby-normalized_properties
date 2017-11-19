module NormalizedProperties
  module Manual
    class Attribute < Attribute
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        @owner.__send__ @config.name
      end
    end
  end
end