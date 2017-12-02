module NormalizedProperties
  class Filter
    OPS = %i(all some one none).freeze

    def initialize(op, *filters)
      raise "invalid filter op" unless OPS.include? op
      @op = op
      @filters = filters
    end

    def satisfied_by?(property)
      value = property.value
      satisfy = ->(filter){ value.satisfies? filter }

      case @op
      when :all
        @filters.all? &satisfy
      when :some
        @filters.any? &satisfy
      when :one
        @filters.one? &satisfy
      when :none
        @filters.none? &satisfy
      else
        false
      end
    end
  end
end