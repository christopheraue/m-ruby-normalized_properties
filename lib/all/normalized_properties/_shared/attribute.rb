module NormalizedProperties
  class Attribute < Property
    def set?
      false
    end

    def satisfies?(filter)
      if @config.model
        filter = {id: filter.property(:id).value} if filter.is_a? @config.model

        case filter
        when Hash
          v = value
          filter.all? do |prop_name, prop_filter|
            v and v.property(prop_name).satisfies? prop_filter
          end
        when true
          !!value
        when false
          !value
        else
          raise ArgumentError, "filter for property #{self} no hash or boolean"
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