module NormalizedProperties
  module Dependent
    class Config < PropertyConfig
      def initialize(owner, name, type, config)
        super owner, name,
          property_class: Dependent.const_get(type),
          filter: config.fetch(:filter),
          model_name: config[:model]

        @sources = config.fetch :sources
        @value = config.fetch :value
      end

      attr_reader :value

      def sources(owner, opts = {intermediate: false}, source = @sources)
        case source
        when Hash
          source.flat_map do |association_name, association_source|
            association = owner.__send__ association_name
            props = []
            props << owner.property(association_name) if opts.fetch(:intermediate)
            props.concat sources(association, opts, association_source) if association
            props
          end
        when Array
          source.flat_map do |owner_source|
            sources owner, opts, owner_source
          end
        else
          [owner.property(source)]
        end
      end
    end
  end
end