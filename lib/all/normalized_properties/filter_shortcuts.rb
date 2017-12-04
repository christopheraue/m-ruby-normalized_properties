module NormalizedProperties
  module FilterShortcuts
    def and(*filters)
      Filter.new :and, *filters
    end

    def or(*filters)
      Filter.new :or, *filters
    end

    def not(*filters)
      Filter.new :not, *filters
    end
  end

  extend FilterShortcuts
end