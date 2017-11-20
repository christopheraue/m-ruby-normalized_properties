module NormalizedProperties
  module Dependent
    class Set < Set
      def initialize(owner, config, filter = {})
        super
        @source_properties = @config.sources(owner).map do |set|
          if filter = @filter[set.name]
            set.where filter
          else
            set
          end
        end
      end

      def source_watches
        @config.sources owner, intermediate: true
      end

      def value
        @config.value.call *@source_properties.map(&:value)
      end

      def reload_value
        @source_properties.each(&:reload_value)
        value
      end
    end
  end
end