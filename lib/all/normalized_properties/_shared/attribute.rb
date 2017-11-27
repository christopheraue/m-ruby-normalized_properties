module NormalizedProperties
  class Attribute < Property
    def value_model
      @config.value_model
    end

    def satisfies?(filter)
      case value = self.value
      when NormalizedProperties::Instance
        case filter
        when true
          true
        when nil
          false
        else
          value.satisfies? filter
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