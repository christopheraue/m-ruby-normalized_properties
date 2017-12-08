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
  end
end