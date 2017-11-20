module NormalizedProperties
  module Dependent
    class Attribute < Attribute
      def initialize(owner, config)
        super
        @source_properties = @config.sources(@owner)
      end

      def source_watches
        @config.sources owner, intermediate: true
      end

      def value
        @config.value.call *@source_properties.map(&:value)
      end

      def reload_value
        @source_properties.each(&:reload_value)
        value
      end
    end
  end
end