module WatchableProperties
  module Dependent
    class Config < PropertyConfig
      def initialize(owner, name, type, config)
        super owner, name,
          property_class: Dependent.const_get(type),
          database_property?: config.fetch(:database_property?, true),
          filter: config.fetch(:filter),
          model_name: config[:model]

        @sources = config.fetch(:sources)
        @filter_base = config.fetch :filter_base if type == 'Set'
      end

      attr_reader :sources, :filter_base

      def source_properties_for(property)
        source_properties property.owner, @sources
      end

      private def source_properties(owner, source)
        case source
        when Hash
          source.flat_map do |association_name, association_source|
            association = owner.__send__ association_name
            props = [owner.property(association_name)]
            props.concat source_properties(association, association_source) if association
            props
          end
        when Array
          source.flat_map do |owner_source|
            source_properties owner, owner_source
          end
        else
          [owner.property(source)]
        end
      end
    end
  end
end