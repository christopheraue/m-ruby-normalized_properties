module NormalizedProperties
  # Usage: `extend NormalizedProperties`
  #
  # The instances of the classes extended with this module get the methods
  # defined in the Instance namespace. Usually, instance and class methods
  # are organized the other way around:
  #
  #   module NormalizedProperties
  #     module ClassMethods
  #       # Definition of class methods
  #     end
  #
  #     # Definition of instance Methods
  #   end
  #
  #   class Model
  #     include NormalizedProperties
  #   end
  #
  # The exact opposite is done here, because including a module also alters
  # constant lookup inside the class it is included into. Example: An
  # Extensions to NormalizedProperties might define
  #
  #   module NormalizedProperties::WorldObject
  #     # Extension
  #   end
  #
  # After `include NormalizedProperties` a simple `WorldObject` in `Model`
  # references `NormalizedProperties::WorldObject` instead the top level
  # `::WorldObject`. To avoid this `extend NormalizedProperties` is used. This
  # does not alter the constant lookup in unexpected ways.

  module Instance
    def property(name)
      @properties ||= {}
      @properties[name] ||= if config = self.class.property_config(name)
                              config.to_property_for self
                            else
                              raise Error, "property #{self.class.name}##{name} does not exist"
                            end
    end

    def satisfies?(filter)
      filter = {id: filter.property(:id).value} if filter.is_a? self.class

      return false unless filter.is_a? Hash

      filter.all? do |prop_name, prop_filter|
        property(prop_name).satisfies? prop_filter
      end
    end
  end

  def self.extended(klass)
    klass.__send__ :include, Instance
    klass.instance_variable_set :@property_configs, {}
  end

  def inherited(klass)
    NormalizedProperties.extended klass
    super
  end

  def normalized_attribute(name, config)
    type = config.delete(:type){ config.fetch :type }
    namespace = if NormalizedProperties.const_defined? type
                  NormalizedProperties.const_get type
                else
                  raise Error, "unknown property type #{type.inspect}"
                end

    config_class = (namespace.const_defined? :AttributeConfig) ? namespace::AttributeConfig : AttributeConfig
    @property_configs[name] = config_class.new self, name, namespace, 'Attribute', config
  end

  def normalized_set(name, config)
    type = config.delete(:type){ config.fetch :type }
    namespace = if NormalizedProperties.const_defined? type
                  NormalizedProperties.const_get type
                else
                  raise Error, "unknown property type #{type.inspect}"
                end

    config_class = (namespace.const_defined? :SetConfig) ? namespace::SetConfig : SetConfig
    @property_configs[name] = config_class.new self, name, namespace, 'Set', config
  end

  def property_config(name)
    @property_configs[name] or if superclass.singleton_class.include? NormalizedProperties
                                 superclass.property_config name
                               end
  end
end