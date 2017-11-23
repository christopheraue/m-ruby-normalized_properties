module NormalizedProperties
  class Set < Property
    def satisfies?(filter)
      if @config.model
        filter = {id: filter.property(:id).value} if filter.is_a? @config.model

        case filter
        when Hash
          not where(filter).value.empty?
        when true
          not value.empty?
        when false
          value.empty?
        else
          raise ArgumentError, "filter for property #{self} no hash or boolean"
        end
      else
        value == filter
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