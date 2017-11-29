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
              result[prop_name] = {__self__: (owner.property prop_name)}
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

      def resolve_filter(filter, opts)
        opts.fetch(:into).merge! @sources_filter.call filter
      end
    end
  end
end