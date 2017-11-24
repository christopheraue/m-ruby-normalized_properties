module NormalizedProperties
  class Set < Property
    def satisfies?(filter)
      filter = {id: filter.property(:id).value} if filter.is_a? NormalizedProperties::Instance

      case filter
      when Hash
        value.any? do |item|
          filter.all? do |prop_name, prop_filter|
            item.property(prop_name).satisfies? prop_filter
          end
        end
      when true
        not value.empty?
      when false
        value.empty?
      else
        raise ArgumentError, "filter for property #{owner.class.name}##{name} no hash or boolean"
      end
    end

    EVENTS_TRIGGERED_BY_WATCHER = %i(changed added removed)

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

    def added!(item)
      trigger :added, item
      trigger :changed
    end

    def removed!(item)
      trigger :removed, item
      trigger :changed
    end
  end
end