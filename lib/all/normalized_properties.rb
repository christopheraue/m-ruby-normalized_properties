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
    namespace_name = config.fetch :type
    namespace = if NormalizedProperties.const_defined? namespace_name
                  NormalizedProperties.const_get namespace_name
                else
                  raise Error, "unknown attribute type #{namespace_name.inspect}"
                end

    @property_configs[name] = namespace::Config.new(self, name, 'Attribute', config)
  end

  def normalized_set(name, config)
    namespace_name = config.fetch :type
    namespace = if NormalizedProperties.const_defined? namespace_name
                  NormalizedProperties.const_get namespace_name
                else
                  raise Error, "unknown set type #{namespace_name.inspect}"
                end

    @property_configs[name] = namespace::Config.new(self, name, 'Set', config)
  end

  def property_config(name)
    @property_configs[name] or if superclass.singleton_class.include? NormalizedProperties
                                 superclass.property_config name
                               end
  end
end