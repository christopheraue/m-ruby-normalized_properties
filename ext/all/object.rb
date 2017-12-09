class Object
  def satisfies?(filter)
    case filter
    when NormalizedProperties::Filter, NormalizedProperties::Set::Filter
      filter.satisfied_by? self
    else
      filter === self
    end
  end
end