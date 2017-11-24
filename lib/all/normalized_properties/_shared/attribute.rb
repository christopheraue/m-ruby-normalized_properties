module NormalizedProperties
  class Attribute < Property
    def satisfies?(filter)
      case value = self.value
      when NormalizedProperties::InstanceMethods
        filter = {id: filter.property(:id).value} if filter.is_a? value.class

        case filter
        when Hash
          filter.all? do |prop_name, prop_filter|
            prop_config = value.class.property_config prop_name
            prop_filter = prop_config.filter_mapper.call prop_filter
            prop_filter.all? do |mapped_name, mapped_filter|
              value.property(mapped_name).satisfies? mapped_filter
            end
          end
        when true
          true
        when nil
          false
        else
          raise ArgumentError, "filter for property #{owner.class.name}##{name} no hash or boolean"
        end
      else
        value == filter
      end
    end

    EVENTS_TRIGGERED_BY_WATCHER = %i(changed)

    def on(*events)
      callback = super

      if self.class::EVENTS_TRIGGERED_BY_WATCHER
        events.each do |event|
          if EVENTS_TRIGGERED_BY_WATCHER.include? event
            @watcher.watch unless @watcher.watching?
            callback.on_cancel{ @watcher.cancel unless EVENTS_TRIGGERED_BY_WATCHER.any?{ |e| on? e } }
          end
        end
      end

      callback
    end

    def changed!
      trigger :changed
    end
  end
end