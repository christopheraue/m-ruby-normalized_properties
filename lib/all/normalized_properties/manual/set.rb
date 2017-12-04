module NormalizedProperties
  module Manual
    class Set < Set
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        @owner.__send__(@config.name).select do |item|
          if item_model
            item.satisfies? @filter
          else
            @filter.satisfied_by? item
          end
        end
      end
    end
  end
end