
module Xcode  
  module Configuration
    
    #
    # Within the a build settings for a configuration there are a number of
    # settings that are stored a space-delimited strings. This helper module
    # provides the opening and saving of these values.
    # 
    # When opened the value returns is going to be an Array.
    # 
    # @example common build settings that are space delimited
    # 
    #     Supported Platforms      : SUPPORTED_PLATFORMS
    #     User Header Search Paths : USER_HEADER_SEARCH_PATHS
    #     Other Test Flags         : OTHER_TEST_FLAGS
    # 
    # @example setting and getting supported platforms
    # 
    #     debug_config project.target('SomeTarget').config('Debug')
    #     debug_config.supported_platforms  # => []
    #     debug_config.supported_platforms = "PLATFORM A"
    #     debug_config.supported_platforms  # => [ "PLATFORM A" ]
    # 
    module SpaceDelimitedString
      extend self
  
      #
      # @param [Nil,String] value stored within the build settings
      # @return [Array<String>] a list of the strings that are within this string
      # 
      def open(value)
        value.to_s.split(" ")
      end
  
      #
      # @param [Array,String] value to be converted into the correct format
      # @return [String] the space-delimited string
      #
      def save(value)
        Array(value).join(" ")
      end
      
      def append(original,value)
        save(open(original) + open(value))
      end
  
    end
    
  end
end