module NormalizedProperties
  module Manual
    class Set < Set
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        @owner.__send__ @config.name
      end

      def where(filter)
        raise Error, 'manual set not filterable'
      end
    end
  end
end