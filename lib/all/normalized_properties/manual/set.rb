module NormalizedProperties
  module Manual
    class Set < Set
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        @owner.__send__(@config.name).select do |item|
          @filter.all? do |prop_name, prop_filter|
            item.property(prop_name).satisfies? prop_filter
          end
        end
      end
    end
  end
end