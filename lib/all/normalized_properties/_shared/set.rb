module NormalizedProperties
  class Set < Property
    def initialize(owner, config, filter = {})
      super owner, config
      @filter = case filter
                when NormalizedProperties::Filter
                  filter
                when {}
                  NormalizedProperties::Filter.new :and
                else
                  NormalizedProperties::Filter.new :and, filter
                end
    end

    def filter
      Filter.new self, @filter
    end

    def dependencies_resolved_filter
      Filter.new self, filter.dependencies_resolved
    end

    def satisfies?(filter)
      case filter
      when true
        not value.empty?
      when false
        value.empty?
      else
        value.any?{ |item| item.satisfies? filter }
      end
    end

    def where(filter)
      case filter
      when {}, nil
        self
      else
        self.class.new @owner, @config, @filter.and(filter)
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