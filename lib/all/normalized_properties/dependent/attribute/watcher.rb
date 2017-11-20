module NormalizedProperties
  module Dependent
    class Attribute
      class Watcher
        def initialize(attribute)
          @attribute = attribute
        end

        def watch
          if @watchers
            raise Error, "already watching"
          else
            @value = @attribute.reload_value
            @watchers = @attribute.source_properties.map do |source_prop|
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

        def trigger_changes
          @previous_value = @value
          @value = @attribute.reload_value
          @attribute.trigger :changed if @value != @previous_value
        end
      end
    end
  end
end