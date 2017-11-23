module NormalizedProperties
  module Manual
    class Attribute < Attribute
      EVENTS_TRIGGERED_BY_WATCHER = false

      def value
        value = @owner.__send__ @config.name

        if @filter and @config.model
          value if value and @filter.all? do |prop_name, prop_filter|
                               value.property(prop_name).satisfies? prop_filter
                             end
        else
          value
        end
      end
    end
  end
end