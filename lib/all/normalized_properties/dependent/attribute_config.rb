module NormalizedProperties
  module Dependent
    class AttributeConfig < AttributeConfig
      include Dependent::PropertyConfig
    end
  end
end