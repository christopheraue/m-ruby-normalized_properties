module NormalizedProperties
  module Manual
    class Set < Set
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        @owner.__send__ @config.name
      end

      def where(filter)
        if filter.empty?
          self
        else
          raise 'manual set not filterable'
        end
      end
    end
  end
end