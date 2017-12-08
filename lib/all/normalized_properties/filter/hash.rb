module NormalizedProperties
  class Filter
    class Hash < Hash
      def self.[](hash)
        mapped = {}
        hash.each{ |k,v| mapped[k] = (::Hash === v) ? Hash[v].freeze : v }
        super mapped
      end

      def dependencies_resolved(model)
        resolved = Hash.new

        each do |prop_name, prop_filter|
          resolved.merge! model.property_config(prop_name).resolve_filter prop_filter
        end

        resolved.each do |prop_name, prop_filter|
          if prop_model = model.property_config(prop_name).model
            resolved[prop_name] = case prop_filter
                                  when Filter, Hash
                                    prop_filter.dependencies_resolved prop_model
                                  else
                                    prop_filter
                                  end
          end
        end

        resolved.freeze
      end
    end
  end
end