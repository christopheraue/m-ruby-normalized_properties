module NormalizedProperties
  module Dependent
    class Config < PropertyConfig
      def initialize(owner, name, type, config)
        super owner, name,
          property_class: Dependent.const_get(type),
          filter: config.fetch(:filter),
          model: config[:model]

        @sources = config.fetch :sources
        @value = config.fetch :value
      end

      attr_reader :value

      def sources(owner, sources = @sources)
        result = {}
        case sources
        when Hash
          sources.each do |prop_name, prop_sources|
            if prop_owner = owner.__send__(prop_name)
              result[prop_name] = {__self__: sources(owner, prop_name)}
              result[prop_name].merge! sources(prop_owner, prop_sources)
            else
              result[prop_name] = nil
            end
          end
        when Array
          sources.each do |source|
            result.merge! sources(owner, source)
          end
        else
          result[sources] = owner.property sources
        end
        result
      end

      def watch_sources(sources)
        case sources
        when Hash
          sources.each_value.flat_map{ |source| watch_sources source }
        when Array
          sources.flat_map{ |source| watch_sources source }
        else
          [sources]
        end
      end
    end
  end
end