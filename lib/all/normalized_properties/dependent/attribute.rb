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
        if value_model
          filter = filter.to_filter if filter.is_a? value_model
          filter = Filter.new :and, filter, value.to_filter unless value.nil?
        end
        filter = Filter.new :and, @config.sources_filter.call(filter)
        owner.satisfies? filter
      end
    end
  end
end