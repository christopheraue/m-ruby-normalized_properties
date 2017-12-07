module NormalizedProperties
  class Property
    include CallbacksAttachable

    def initialize(owner, config)
      @owner = owner
      @config = config
      @name = config.name
      @model = config.model
      @to_s = "#{@owner}##{@name}".freeze
      @watcher = self.class::Watcher.new(self) if self.class::EVENTS_TRIGGERED_BY_WATCHER
    end

    attr_reader :owner, :name, :model, :to_s

    def value
      raise NotImplementedError, "must be implemented by subclass"
    end

    def ==(other)
      self.class === other and @owner == other.owner and @name == other.name
    end
  end
end