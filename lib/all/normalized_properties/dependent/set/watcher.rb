module NormalizedProperties
  module Dependent
    class Set
      class Watcher < Watcher
        def trigger_changes
          @previous_value = @value
          @value = @property.value

          if @value != @previous_value
            @property.trigger :changed

            (@value - @previous_value).each do |item|
              @property.trigger :added, item
            end

            (@previous_value - @value).each do |item|
              @property.trigger :removed, item
            end
          end
        end
      end
    end
  end
end