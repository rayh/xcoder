
module Xcode
  
  class Resource
    
    attr_accessor :identifier, :properties, :registry
    
    def is_identifier? value
      value =~ /^[0-9A-F]{24}$/
    end
    
    #
    # Define Property allows the creation of an alias to the actual value 
    # contained by defining our own custom getter for any defined value. This is
    # useful for objects which are represented as project object identifiers 
    # which will instead return the referenced objects and not simply their 
    # identifier.
    # 
    def define_property name, value
      
      # define a property but we need to immediately replace any references
      # or we need to define a filter
      
      
      @properties[name] = value
      # set an instance variable to hold the value
      #instance_variable_set "@#{name}", value
      
      # then we want to define a method for retrieving the value that will do some replacement
      self.class.send :define_method, name do
        
        raw_value = @properties[name]
        
        # does the raw value contain any keys, then we need to convert them to full items
        # E2F11AAF14DC9209004101FD
        
        if raw_value.is_a?(Array)
          Array(raw_value).map do |sub_value|
            if is_identifier? sub_value 
              
              Resource.new sub_value, @registry
              
              #@registry['objects'][sub_value]
            else
              sub_value
            end
          end
          
        else 
          if is_identifier? raw_value
            Resource.new raw_value, @registry
            #@registry['objects'][raw_value]
          else 
            raw_value
          end
        end

      end
      
    end

    def initialize identifier, details
      @registry = details
      @properties = {}
      @identifier = identifier
      details['objects'][@identifier].each do |key,value| 
        send :define_property, key, value
      end
      
    end
    
    def to_s
      "#{isa} #{@identifier} #{@properties}"
    end
    
  end
  
end