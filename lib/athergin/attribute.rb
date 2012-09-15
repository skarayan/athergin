module Attribute
  def attribute(*names)
    names.each do |name|
      instance_variable_name = :"@#{ name }"
      define_method name do |value=nil|
        value ? instance_variable_set(instance_variable_name,value) : instance_variable_get(instance_variable_name)
      end
    end
  end
end
