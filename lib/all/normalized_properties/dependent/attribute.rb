module NormalizedProperties
  module Dependent
    class Attribute < Attribute
      def source_properties
        @config.source_properties_for self
      end

      def value
        @owner.__send__ @name
      end

      def reload_value
        source_properties.each(&:reload_value)
        value
      end
    end
  end
end