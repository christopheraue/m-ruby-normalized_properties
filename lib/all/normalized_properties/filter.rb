module NormalizedProperties
  class Filter
    OPS = {all: :all?, some: :any?, one: :one?, none: :none?}.freeze

    def initialize(op, *filters)
      @op = op
      @filters = filters
      @filter_method = OPS[op] or raise "invalid filter op"
    end

    def satisfied_by?(property)
      if property.is_a? Set
        items = property.value
        @filters.__send__(@filter_method){ |filter| items.any?{ |item| item.satisfies? filter } }
      else
        value = property.value
        @filters.__send__(@filter_method){ |filter| value.satisfies? filter }
      end
    end
  end
end