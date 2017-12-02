module NormalizedProperties
  class Set < Property
    def initialize(owner, config, filter = {})
      super owner, config
      @filter = filter
    end

    attr_reader :filter

    def dependencies_resolved_filter
      item_model.resolve_dependent_filter @filter
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
      raise ArgumentError, "filter no hash" unless filter.is_a? Hash

      if filter.empty?
        self
      else
        self.class.new @owner, @config, merge_filter(@filter, filter)
      end
    end

    private def merge_filter!(filter1, filter2)
      merged = filter1
      filter2.each do |key, value|
        merged[key] = if merged[key].is_a? Hash and value.is_a? Hash
                        merge_filter! merged[key], value
                      else
                        value
                      end
      end
      merged
    end

    private def merge_filter(filter1, filter2)
      merge_filter! filter1.dup, filter2
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