module WatchableProperties
  class Set < Property
    def initialize(owner, config, filter = {})
      super owner, config
      @filter = filter
      @model = config.model
    end

    attr_reader :filter, :model

    def set?
      true
    end

    def where(filter)
      if filter.empty?
        self
      else
        self.class.new @owner, @config, @filter.deep_merge(prepare_filter filter)
      end
    end

    private def prepare_filter(filter, model = @model)
      filter.inject({}) do |prepared, (prop_name, prop_filter)|
        model.property_config(prop_name).filter_mapper.call(prop_filter).each do |prop_name2, prop_filter2|
          prop_model = model.property_config(prop_name2).model
          if prop_model and prop_filter2.is_a? Hash
            prepared.deep_merge! model.property_config(prop_name2).filter_mapper.call prepare_filter(prop_filter2, prop_model)
          else
            prepared[prop_name2] = prop_filter2
          end
        end
        prepared
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
  end
end