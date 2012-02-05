
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
            else
              sub_value
            end
          end
          
        else 
          if is_identifier? raw_value
            Resource.new raw_value, @registry
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
      
      Array(details.object(@identifier)).each do |key,value| 
        send :define_property, key, value
      end
      
      #  
      # Based on the `isa` property find if there is a constant within
      # the Xcode module that matches and if it does, then we want to 
      # automatically include module into the Resource object.
      # 
      begin
        constant = Xcode.const_get(isa)
        self.class.class_eval do
          include constant
        end
        
      rescue => exception
        # puts "#{exception}"
      end
      
    end
    
    def to_s
      "#{isa} #{@identifier} #{@properties}"
    end
    
    def to_xcplist
      %{
        #{@identifier} = { #{ @properties.map {|k,v| "#{k} = \"#{v}\"" }.join("; ") } }
        
      }
    end
    
  end
  
end