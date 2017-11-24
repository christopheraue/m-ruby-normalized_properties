module NormalizedProperties
  class Property
    include CallbacksAttachable

    def initialize(owner, config, filter = {})
      @owner = owner
      @config = config
      @filter = filter
      @name = config.name
      @model = config.model
      @to_s = "#{@owner}##{@name}".freeze
      @watcher = self.class::Watcher.new(self) if self.class::EVENTS_TRIGGERED_BY_WATCHER
    end

    attr_reader :owner, :name, :to_s, :filter, :model

    def value
      raise NotImplementedError, "must be implemented by subclass"
    end

    def ==(other)
      self.class === other and @owner == other.owner and @name == other.name
    end

    def where(filter)
      raise ArgumentError, "filter no hash" unless filter.is_a? Hash

      if filter.empty?
        self
      else
        self.class.new @owner, @config, merge_filter(@filter, filter)
      end
    end

    private def merge_filter(filter1, filter2)
      merge_filter! filter1.dup, filter2
    end

    private def merge_filter!(filter1, filter2)
      merged = filter1
      filter2.each do |key, value|
        merged[key] = if merged[key].is_a? Hash and value.is_a? Hash
                        deep_merge! merged[key], value
                      else
                        value
                      end
      end
      merged
    end
  end
end