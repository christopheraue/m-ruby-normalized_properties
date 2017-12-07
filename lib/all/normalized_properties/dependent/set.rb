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
        if @model
          filter = filter.to_filter if filter.is_a? @model
          filter = Filter.new :and, filter, (NP.or *(value.map &:to_filter)) unless value.empty?
        end
        filter = Filter.new :and, @config.sources_filter.call(filter)
        owner.satisfies? filter
      end
    end
  end
end