module NormalizedProperties
  class Filter
    class Hash < Hash
      def self.[](hash)
        mapped = {}
        hash.each{ |k,v| mapped[k] = (::Hash === v) ? Hash[v].freeze : v }
        super mapped
      end

      alias noop? empty?

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

      def partition_by(namespace, prop_namespace, prop_model)
        if prop_model
          type_filter = Hash.new
          other_filter = Hash.new

          each do |prop_name, prop_filter|
            prop_config = prop_model.property_config prop_name

            case prop_filter
            when Filter, Hash
              tfs, ofs = prop_filter.partition_by namespace, prop_config.namespace, prop_config.model
              type_filter[prop_name] = tfs unless tfs.noop?
              other_filter[prop_name] = ofs unless ofs.noop?
            else
              if prop_config.namespace == namespace
                type_filter[prop_name] = prop_filter
              else
                other_filter[prop_name] = prop_filter
              end
            end
          end
        else
          if prop_namespace == namespace
            type_filter = self
            other_filter = Hash.new
          else
            type_filter = Hash.new
            other_filter = self
          end
        end

        [type_filter.freeze, other_filter.freeze]
      end
    end
  end
end