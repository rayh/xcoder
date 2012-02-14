
module Xcode
  module Configuration
    
    #
    # Within the a build settings for a configuration there are a number of
    # settings that are stored as Objective-C boolean values. This helper module
    # provides the opening and saving of these values.
    # 
    # When opened the value returns is going to be an Array.
    # 
    # @example common build settings that are booleans
    # 
    # @example setting and getting a property
    # 
    module BooleanProperty
      extend self
    
      # 
      # @param [Nil,TrueClass,FalseClass,String] value to convert to boolean
      # @return [TrueClass,FalseClass] the boolean value based on the specified
      #   value.
      # 
      def load(value)
        value.to_s =~ /^YES$/
      end
    
      #
      # @param [String,FalseClass,TrueClass] value to convert to the Obj-C boolean
      # @return [String] YES or NO
      #
      def save(value)
        value ? "YES" : "NO"
      end
  
    end
    
  end
end