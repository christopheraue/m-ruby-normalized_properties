module WatchableProperties
  module InstanceMethods
    def property(name)
      @properties ||= {}
      @properties[name] ||= if config = self.class.property_config(name)
                              config.to_property_for self
                            else
                              raise "property #{name.inspect} does not exist"
                            end
    end
  end

  def self.extended(klass)
    klass.__send__ :include, InstanceMethods
    klass.instance_variable_set :@property_configs, {}
  end

  def inherited(klass)
    WatchableProperties.extended klass
    super
  end

  def watchable_attribute(name, config)
    namespace_name = config.fetch :type
    namespace = if WatchableProperties.const_defined? namespace_name
                  WatchableProperties.const_get namespace_name
                else
                  raise "unknown attribute type #{namespace_name.inspect}"
                end

    @property_configs[name] = namespace::Config.new(self, name, 'Attribute', config)
  end

  def watchable_set(name, config)
    namespace_name = config.fetch :type
    namespace = if WatchableProperties.const_defined? namespace_name
                  WatchableProperties.const_get namespace_name
                else
                  raise "unknown set type #{namespace_name.inspect}"
                end

    @property_configs[name] = namespace::Config.new(self, name, 'Set', config)
  end

  def property_config(name)
    @property_configs[name] or (superclass.singleton_class.include? WatchableProperties and superclass.property_config name)
  end
end