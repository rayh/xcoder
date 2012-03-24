
module Xcode
  module Configuration
    
    #
    # Within the a build settings for a configuration there are a number of
    # settings that are stored simply as strings. This helper module
    # is for the most part a pass-through method to provide parity with the 
    # other methods.
    # 
    module StringProperty
      extend self
      
      def open(value)
        value.to_s
      end
  
      def save(value)
        value.to_s
      end
      
      def append(original,value)
        open(original) + value.to_s
      end
  
    end
    
  end
end
