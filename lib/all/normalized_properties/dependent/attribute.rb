module NormalizedProperties
  module Dependent
    class Attribute < Attribute
      def initialize(owner, config)
        super
        @sources = @config.sources @owner
      end

      def watch_sources
        @config.flattened_sources @sources
      end

      def value
        @owner.instance_exec @sources, &@config.value
      end
    end
  end
end