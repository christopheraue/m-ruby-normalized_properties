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
        when Filter
          part.dependencies_resolved model
        when Hash
          hash_dependencies_resolved model, part
        else
          part
        end
      end)
    end

    def hash_dependencies_resolved(model, hash)
      resolved_part = {}

      hash.each do |prop_name, prop_filter|
        resolved_part.merge! model.property_config(prop_name).resolve_filter prop_filter
      end

      resolved_part.each do |prop_name, prop_filter|
        if prop_model = model.property_config(prop_name).model
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