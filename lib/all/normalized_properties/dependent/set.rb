module NormalizedProperties
  module Dependent
    class Set < Set
      def initialize(owner, config, filter = {})
        super
        filter_base = owner.instance_exec &config.filter_base
        @filtered = filter.empty? ? filter_base : filter_base.where(filter)
      end

      attr_reader :filtered

      def source_properties
        @config.source_properties_for self
      end

      def value
        @owner.__send__ @name
      end

      def reload_value
        filter_base = @owner.instance_exec &@config.filter_base
        @filtered = @filter.empty? ? filter_base : filter_base.where(@filter)
        value
      end
    end
  end
end