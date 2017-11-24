module NormalizedProperties
  module Manual
    class Attribute < Attribute
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        case value = @owner.__send__(@config.name)
        when NormalizedProperties::InstanceMethods
          satisfies_filter = if @filter
                               @filter.all? do |prop_name, prop_filter|
                                 value.property(prop_name).satisfies? prop_filter
                               end
                             else
                               true
                             end

          value if satisfies_filter
        else
          value
        end
      end
    end
  end
end