module NormalizedProperties
  module Manual
    class Set < Set
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        @owner.__send__(@config.name).select do |item|
          if item_model
            @filter.satisfied_by_instance? item
          else
            @filter.satisfied_by_value? item
          end
        end
      end
    end
  end
end