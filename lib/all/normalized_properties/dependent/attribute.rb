module NormalizedProperties
  module Dependent
    class Attribute < Attribute
      def watch_sources
        @config.watch_sources @config.sources(@owner)
      end

      def value
        @owner.instance_exec @config.sources(@owner), &@config.value
      end
    end
  end
end