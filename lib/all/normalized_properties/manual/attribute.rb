module NormalizedProperties
  module Manual
    class Attribute < Attribute
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        case value = @owner.__send__(@config.name)
        when NormalizedProperties::Instance
          value if not @filter or value.satisfies? @filter
        else
          value
        end
      end
    end
  end
end