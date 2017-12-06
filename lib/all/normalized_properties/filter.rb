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

    def satisfied_by_model_instance?(instance)
      @parts.__send__(@filter_method) do |part|
        case part
        when Filter
          part.satisfied_by_model_instance? instance
        else
          part.all? do |prop_name, prop_filter|
            instance.property(prop_name).satisfies? prop_filter
          end
        end
      end
    end

    def satisfied_by_object?(value)
      @parts.__send__(@filter_method) do |part|
        case part
        when Filter
          part.satisfied_by_object? value
        else # simple value
          value == part
        end
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
          part.dependencies_resolved item_model
        when Hash
          hash_dependencies_resolved item_model, part
        else
          part
        end
      end)
    end

    def hash_dependencies_resolved(item_model, hash)
      resolved_part = {}

      hash.each do |prop_name, prop_filter|
        resolved_part.merge! item_model.property_config(prop_name).resolve_filter prop_filter
      end

      resolved_part.each do |prop_name, prop_filter|
        if prop_model = item_model.property_config(prop_name).model
          resolved_part[prop_name] = case prop_filter
                                     when Filter
                                       prop_filter.dependencies_resolved prop_model
                                     when Hash
                                       hash_dependencies_resolved prop_model, prop_filter
                                     else
                                       prop_filter
                                     end
        end
      end

      resolved_part
    end
  end
end