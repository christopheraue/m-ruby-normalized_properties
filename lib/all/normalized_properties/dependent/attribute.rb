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
        filter = filter.to_filter if value_model and filter.is_a? value_model
        filter = Filter.new :and, filter, @config.value_filter.call(value) if @config.value_filter
        filter = Filter.new :and, @config.sources_filter.call(filter)
        owner.satisfies? filter
      end
    end
  end
end