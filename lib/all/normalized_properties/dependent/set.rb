module NormalizedProperties
  module Dependent
    class Set < Set
      def watch_sources
        @config.watch_sources @config.sources(@owner)
      end

      def value
        @owner.instance_exec(@config.sources(@owner), &@config.value).select do |item|
          if item_model
            item.satisfies? @filter
          else
            @filter.satisfied_by? item
          end
        end
      end

      def satisfies?(filter)
        filter = Filter.new :and, filter if filter.is_a? Hash or filter.is_a? Instance
        filter = filter.and @config.value_filter.call(value) if @config.value_filter
        owner.satisfies? Filter.new :and, @config.sources_filter.call(filter)
      end
    end
  end
end