module WatchableProperties
  module Dependent
    class Set < Set
      def initialize(owner, config, filter = {})
        super
        filter_base = owner.instance_exec &config.filter_base
        @set = filter.empty? ? filter_base : filter_base.where(filter)
      end

      def source_properties
        @config.source_properties_for self
      end

      def value
        @set.value
      end

      def reload_value
        filter_base = @owner.instance_exec &@config.filter_base
        @set = @filter.empty? ? filter_base : filter_base.where(@filter)
        @set.reload_value
      end
    end
  end
end