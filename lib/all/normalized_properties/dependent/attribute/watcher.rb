module NormalizedProperties
  module Dependent
    class Attribute
      class Watcher < Watcher
        def trigger_changes
          @previous_value = @value
          @value = @property.value
          @property.changed! @value if @value != @previous_value
        end
      end
    end
  end
end