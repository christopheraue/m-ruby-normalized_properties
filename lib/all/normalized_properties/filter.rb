module NormalizedProperties
  class Filter
    OPS = {and: :all?, or: :any?, not: :none?}.freeze

    def initialize(op, *parts)
      @op = op
      @parts = parts.map{ |part| (::Hash === part) ? Hash[part].freeze : part }.freeze
      @filter_method = OPS[op] or raise "invalid filter op"
      freeze
    end

    attr_reader :op, :parts

    def noop?
      if @op == :or
        false # [].any? is false
      else
        @parts.empty?
      end
    end

    def satisfied_by?(object)
      @parts.__send__(@filter_method) do |part|
        object.satisfies? part
      end
    end

    def and(filter)
      if @op == :and
        Filter.new :and, *@parts, filter
      else
        Filter.new :and, self, filter
      end
    end

    def dependencies_resolved(model)
      Filter.new @op, *(@parts.map do |part|
        case part
        when Filter, Hash
          part.dependencies_resolved model
        else
          part
        end
      end)
    end

    def partition_by(namespace, prop_namespace, prop_model)
      if prop_model
        type_parts = []
        other_parts = []

        @parts.each do |part|
          case part
          when Filter, Hash
            tps, ops = part.partition_by namespace, prop_namespace, prop_model
            type_parts << tps unless tps.noop?
            other_parts << ops unless ops.noop?
          else
            if prop_namespace == namespace and prop_model === part
              type_parts << part
            else
              other_parts << part
            end
          end
        end

        type_filter = Filter.new @op, *type_parts
        other_filter = Filter.new @op, *other_parts
      else
        if prop_namespace == namespace
          type_filter = self
          other_filter = Filter.new @op
        else
          type_filter = Filter.new @op
          other_filter = self
        end
      end

      [type_filter, other_filter]
    end
  end
end