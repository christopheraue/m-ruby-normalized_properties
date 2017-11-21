module NormalizedProperties
  module Dependent
    class Config < PropertyConfig
      def initialize(owner, name, type, config)
        super owner, name,
          property_class: Dependent.const_get(type),
          filter: config.fetch(:filter),
          model_name: config[:model]

        @sources = config.fetch :sources
        @value = config.fetch :value
      end

      attr_reader :value

      def sources(owner, sources = @sources)
        result = {}
        case sources
        when Hash
          sources.each do |prop_name, prop_sources|
            result[prop_name] = {__self__: sources(owner, prop_name)}
            result[prop_name].merge! sources(owner.__send__(prop_name), prop_sources)
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

      def reload_sources(sources)
        case sources
        when Hash
          sources.each_value{ |prop_sources| reload_sources prop_sources }
        when Array
          sources.each{ |source| reload_sources(source) }
        else
          sources.reload_value
        end
      end

      def flattened_sources(sources)
        result = []
        case sources
        when Hash
          sources.each_value{ |prop_sources| result.concat flattened_sources prop_sources }
        when Array
          sources.each{ |source| result.concat flattened_sources(source) }
        else
          result.push sources
        end
        result
      end
    end
  end
end