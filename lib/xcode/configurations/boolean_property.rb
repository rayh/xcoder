
module Xcode
  module Configuration
    
    #
    # Within the a build settings for a configuration there are a number of
    # settings that are stored as Objective-C boolean values. This helper module
    # provides the opening and saving of these values.
    # 
    # When opened the value returns is going to be an Array.
    # 
    # @example setting and getting a property
    # 
    #     debug_config project.target('SomeTarget').config('Debug')
    #     debug_config.always_search_user_paths  # => false
    #     debug_config.always_search_user_paths = true
    #     debug_config.always_search_user_paths  # true
    # 
    module BooleanProperty
      extend self
    
      # 
      # @param [Nil,TrueClass,FalseClass,String] value to convert to boolean
      # @return [TrueClass,FalseClass] the boolean value based on the specified
      #   value.
      # 
      def open(value)
        value.to_s =~ /^YES$/
      end
    
      #
      # @param [String,FalseClass,TrueClass] value to convert to the Obj-C boolean
      # @return [String] YES or NO
      #
      def save(value)
        value.to_s =~ /^(?:NO|false)$/ ? "NO" : "YES"
      end
      
      #
      # @note Appending boolean properties has no real good default operation. What
      #   happens in this case is that whatever you decide to append will automatically
      #   override the previously existing settings.
      # 
      # @param [Types] original the original value to be appended
      # @param [Types] value Description
      #
      def append(original,value)
        save(value)
      end
  
    end
    
  end
end
