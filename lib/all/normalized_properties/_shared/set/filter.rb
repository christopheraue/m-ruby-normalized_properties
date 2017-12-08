module NormalizedProperties
  class Set
    class Filter
      def initialize(set, filter)
        @set = set
        @filter = filter
      end

      def op
        @filter.op
      end

      def parts
        @filter.parts
      end

      def dependencies_resolved
        if @set.model
          Filter.new @set, @filter.dependencies_resolved(@set.model)
        else
          self
        end
      end
    end
  end
end