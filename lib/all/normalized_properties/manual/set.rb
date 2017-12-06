module NormalizedProperties
  module Manual
    class Set < Set
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        @owner.__send__(@config.name).select do |item|
          if item_model
            @filter.satisfied_by_model_instance? item
          else
            @filter.satisfied_by_object? item
          end
        end
      end
    end
  end
end