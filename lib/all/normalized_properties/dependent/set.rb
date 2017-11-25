module NormalizedProperties
  module Dependent
    class Set < Set
      def watch_sources
        @config.watch_sources @config.sources(@owner)
      end

      def value
        @owner.instance_exec @config.sources(@owner), &@config.value
      end

      def satisfies?(filter)
        filter = @config.filter_mapper.call filter
        filter.all? do |prop_name, prop_filter|
          owner.property(prop_name).satisfies? prop_filter
        end
      end
    end
  end
end