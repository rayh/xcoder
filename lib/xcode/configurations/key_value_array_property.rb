
module Xcode
  module Configuration
    
    #
    # Within the a build settings for a configuration there are a number of
    # settings that are stored as key-value pairs in Arrays.
    # 
    module KeyValueArrayProperty
      extend self
  
      #
      # As arrays are stored as arrays this is not particularly different.
      # 
      # @param [Array] value to be parsed into the correct format
      #
      def open(value)
        Array(value)
      end
    
      #
      # @param [Nil,Array,String] value that is being saved back which can
      #   be in a multitude of formats as long as it responds_to? #to_a
      #
      def save(value)
        Array(value)
      end
      
      #
      # To ensure uniqueness, the original value array is added to the new value
      # array and then all the key-values pairs are placed in a Hash then mapped
      # back out to a key=value pair array.
      # 
      def append(original,value)
        all_values = (open(original) + Array(value)).map {|key_value| key_value.split("=") }.flatten
        Hash[*all_values].map {|k,v| "#{k}=#{v}" }
      end
  
    end
    
  end
end
