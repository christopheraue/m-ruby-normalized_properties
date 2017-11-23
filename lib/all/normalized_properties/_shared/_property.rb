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
        self.class.new @owner, @config, merge_filter(@filter, prepare_filter(filter))
      end
    end

    private def prepare_filter(filter, model = @model)
      filter.inject({}) do |prepared, (prop_name, prop_filter)|
        unless prop_config = model.property_config(prop_name)
          raise ArgumentError, "filter contains unknown property #{model}##{prop_name}"
        end
        real_filter = prop_config.filter_mapper.call prop_filter

        real_filter.each do |real_prop_name, real_prop_filter|
          unless real_prop_config = model.property_config(real_prop_name)
            raise ArgumentError, "filter contains unknown property #{model}##{real_prop_name}"
          end

          real_prop_filter = if real_prop_config.model
                               if real_prop_filter.is_a? real_prop_config.model
                                 real_prop_filter = {id: real_prop_filter.property(:id).value}
                               end

                               case real_prop_filter
                               when Hash
                                 prepare_filter real_prop_filter, real_prop_config.model
                               when true, false
                                 real_prop_filter
                               else
                                 raise ArgumentError, "filter for property #{model}##{real_prop_name} no hash or boolean"
                               end
                             else
                               real_prop_filter
                             end

          merge_filter! prepared, {real_prop_name => real_prop_filter}
        end
        prepared
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