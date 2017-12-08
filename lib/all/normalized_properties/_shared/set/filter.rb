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

      def satisfied_by?(object)
        @filter.satisfied_by? object
      end

      def dependencies_resolved
        if @set.model
          Filter.new @set, @filter.dependencies_resolved(@set.model)
        else
          self
        end
      end

      def partition_by(type)
        namespace = if NormalizedProperties.const_defined? type
                      NormalizedProperties.const_get type
                    else
                      raise Error, "unknown property type #{type.inspect}"
                    end

        @filter.partition_by(namespace, @set.namespace, @set.model).map do |part|
          if part == @filter
            self
          else
            Filter.new @set, part
          end
        end
      end
    end
  end
end