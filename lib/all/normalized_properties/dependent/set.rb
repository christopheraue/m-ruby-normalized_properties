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
        filter = filter.to_filter if item_model and filter.is_a? item_model
        filter = Filter.new :and, filter, @config.value_filter.call(value) if @config.value_filter
        filter = Filter.new :and, @config.sources_filter.call(filter)
        owner.satisfies? filter
      end
    end
  end
end