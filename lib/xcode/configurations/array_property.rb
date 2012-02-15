
module Xcode
  module Configuration
    
    #
    # Within the a build settings for a configuration there are a number of
    # settings that are stored as Arrays. This helper module is for the most part 
    # a pass-through method to provide parity with the other methods.
    # 
    module ArrayProperty
      extend self
  
      #
      # As arrays are stored as arrays this is not particularly different.
      # 
      # @param [Array] value to be parsed into the correct format
      #
      def open(value)
        value.to_a
      end
    
      #
      # @param [Nil,Array,String] value that is being saved back which can
      #   be in a multitude of formats as long as it responds_to? #to_a
      #
      def save(value)
        value.to_s
      end
  
    end
    
  end
end