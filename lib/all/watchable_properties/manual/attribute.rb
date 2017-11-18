module WatchableProperties
  module Manual
    class Attribute < Attribute
      EVENTS_TRIGGERED_BY_WATCHER = false
      
      def initialize(owner, *)
        super
        @value = owner.__send__ @config.name
      end

      attr_reader :value

      on :changed do |new_value|
        @value = new_value
      end
    end
  end
end