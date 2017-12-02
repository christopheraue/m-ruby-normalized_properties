module NormalizedProperties
  class Filter
    OPS = {all: :all?, some: :any?, one: :one?, none: :none?}.freeze

    def initialize(op, *filters)
      @op = op
      @filters = filters
      @filter_method = OPS[op] or raise "invalid filter op"
    end

    def satisfied_by?(object)
      case object
      when Instance
        @filters.__send__(@filter_method) do |filter|
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
        @filters.__send__(@filter_method){ |filter| items.any?{ |item| item.satisfies? filter } }
      else
        value = object.value
        @filters.__send__(@filter_method){ |filter| value.satisfies? filter }
      end
    end

    def and(filter)
      if @op == :all
        Filter.new :all, *@filters, filter
      else
        Filter.new :all, self, filter
      end
    end
  end
end