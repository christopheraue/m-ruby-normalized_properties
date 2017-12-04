module NormalizedProperties
  class Filter
    OPS = {and: :all?, or: :any?, not: :none?}.freeze

    def initialize(op, *parts)
      @op = op
      @parts = parts
      @filter_method = OPS[op] or raise "invalid filter op"
    end

    attr_reader :op

    def parts
      @parts.dup.freeze
    end

    def satisfied_by?(object)
      case object
      when Instance
        @parts.__send__(@filter_method) do |filter|
          case filter
          when Filter
            filter.satisfied_by? object
          else
            filter.all? do |prop_name, prop_filter|
              object.property(prop_name).satisfies? prop_filter
            end
          end
        end
      when Set
        items = object.value
        items.any?{ |item| @parts.__send__(@filter_method){ |filter| item.satisfies? filter } }
      else
        value = object.value
        @parts.__send__(@filter_method){ |filter| value.satisfies? filter }
      end
    end

    def and(filter)
      if @op == :and
        Filter.new :and, *@parts, filter
      else
        Filter.new :and, self, filter
      end
    end

    def dependencies_resolved(item_model)
      Filter.new @op, *(@parts.map do |part|
        case part
        when Filter
          part.resolve_dependencies
        else
          resolved_part = {}
          part.each do |prop_name, prop_filter|
            resolved_part.merge! item_model.property_config(prop_name).resolve_filter prop_filter
          end

          resolved_part.each do |prop_name, prop_filter|
            if model = item_model.property_config(prop_name).model
              resolved_part[prop_name] = model.resolve_dependent_filter prop_filter
            end
          end

          resolved_part
        end
      end)
    end
  end
end