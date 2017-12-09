module NormalizedProperties
  module Dependent
    module PropertyConfig
      def initialize(owner, name, namespace, config)
        super
        @sources = config.fetch :sources
        @value = config.fetch :value
        @sources_filter = config.fetch :sources_filter
      end

      attr_reader :value, :sources_filter

      def sources(owner, sources = @sources)
        result = {}
        case sources
        when Hash
          sources.each do |prop_name, prop_sources|
            if prop_owner = owner.property(prop_name).value
              result[prop_name] = {__property__: owner.property(prop_name)}
              case prop_owner
              when Array
                result[prop_name].merge! __children__: prop_owner.map{ |o| sources o, prop_sources }
              else
                result[prop_name].merge! sources(prop_owner, prop_sources)
              end
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

      def resolve_filter(filter)
        resolved_filter = {}
        @sources_filter.call(filter).each do |prop_name, prop_filter|
          resolved_filter.merge! @owner.property_config(prop_name).resolve_filter prop_filter
        end
        resolved_filter
      end
    end
  end
end