module NormalizedProperties
  module Dependent
    class AttributeConfig < AttributeConfig
      include Dependent::PropertyConfig

      def initialize(owner, name, namespace, config)
        super
        @value_filter = config[:value_filter]
      end

      attr_reader :value_filter
    end
  end
end