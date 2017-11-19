module NormalizedProperties
  module Dependent
    class Set
      class Watcher
        def initialize(set)
          @set = set
        end

        def watch
          if @watchers
            raise Error, "already watching"
          else
            @value = @set.reload_value
            @watchers = @set.source_properties.map do |source_prop|
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
          @value = @set.reload_value

          if @value != @previous_value
            @set.trigger :changed

            (@value - @previous_value).each do |item|
              @set.trigger :added, item
            end

            (@previous_value - @value).each do |item|
              @set.trigger :removed, item
            end
          end
        end
      end
    end
  end
end