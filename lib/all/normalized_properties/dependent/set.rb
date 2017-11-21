module NormalizedProperties
  module Dependent
    class Set < Set
      def initialize(owner, config, filter = {})
        super
        @sources = @config.sources(owner)
      end

      def watch_sources
        @config.flattened_sources @sources
      end

      def value
        @owner.instance_exec @sources, &@config.value
      end

      def reload_value
        @config.reload_sources @sources
        value
      end
    end
  end
end