module NormalizedProperties
  class Set < Property
    def initialize(owner, config, filter = nil)
      super owner, config
      @filter = (filter or Filter.new :and)
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
        if item_model
          filter.satisfied_by? self
        else
          value.any?{ |item| filter.satisfied_by? item }
        end
      else
        if item_model
          value.any?{ |item| item.satisfies? filter }
        else
          value.any?{ |item| item == filter }
        end
      end
    end

    def where(filter)
      if filter == {} or filter == nil
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