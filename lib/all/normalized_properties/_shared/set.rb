module NormalizedProperties
  class Set < Property
    def initialize(owner, config, filter = nil)
      super owner, config
      @filter = (filter or Filter.new :all)
    end

    attr_reader :filter

    def dependencies_resolved_filter
      @filter.dependencies_resolved item_model
    end

    def item_model
      @config.model
    end

    def satisfies?(filter)
      case filter
      when true
        not value.empty?
      when false
        value.empty?
      when Filter
        filter.satisfied_by? self
      else
        value.any?{ |item| item.satisfies? filter }
      end
    end

    def where(filter)
      case filter
      when Hash, Filter
        if filter == {}
          self
        else
          self.class.new @owner, @config, @filter.and(filter)
        end
      else
        raise ArgumentError, "filter no hash or #{NormalizedProperties::Filter}"
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