module NormalizedProperties
  module Dependent
    class Set < Set
      def watch_sources
        @config.watch_sources @config.sources(@owner)
      end

      def value
        @owner.instance_exec(@config.sources(@owner), &@config.value).select do |item|
          item.satisfies? @filter
        end
      end

      def satisfies?(filter)
        filter = @config.sources_filter.call filter
        filter.all? do |prop_name, prop_filter|
          owner.property(prop_name).satisfies? prop_filter
        end
      end
    end
  end
end