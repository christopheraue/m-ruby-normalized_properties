module NormalizedProperties
  module Manual
    class Set < Set
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        @owner.__send__(@name).select do |item|
          item.satisfies? @filter
        end
      end
    end
  end
end