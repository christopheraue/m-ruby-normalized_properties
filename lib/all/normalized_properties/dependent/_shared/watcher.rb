module NormalizedProperties
  module Dependent
    class Watcher
      def initialize(property)
        @property = property
      end

      def watch
        if @watchers
          raise Error, "already watching"
        else
          @value = @property.value
          @watchers = @property.watch_sources.map do |source_prop|
            source_prop.on(:changed){ trigger_changes }
          end
        end
      end

      def watching?
        !!@watchers
      end

      def cancel
        remove_instance_variable(:@watchers).each(&:cancel)
      end
    end
  end
end