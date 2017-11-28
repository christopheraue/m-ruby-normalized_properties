module NormalizedProperties
  module Dependent
    class Attribute < Attribute
      def watch_sources
        @config.watch_sources @config.sources(@owner)
      end

      def value
        @owner.instance_exec @config.sources(@owner), &@config.value
      end

      def satisfies?(filter)
        case filter
        when Hash
          filter.merge! @config.value_filter.call value if @config.value_filter
          filter = @config.filter_mapper.call filter
          filter.all? do |prop_name, prop_filter|
            owner.property(prop_name).satisfies? prop_filter
          end
        else
          filter == value
        end
      end
    end
  end
end