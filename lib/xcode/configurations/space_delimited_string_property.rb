
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
      # While the space delimited string can and is often stored in that way,
      # it appears as though Xcode is now possibly storing these values in a format
      # that the parser is returning as an Array. So if the raw value is an
      # array, simply return that raw value instead of attempting to convert it.
      # 
      # @param [Nil,String] value stored within the build settings
      # @return [Array<String>] a list of the strings that are within this string
      # 
      def open(value)
        value.is_a?(Array) ? value : value.to_s.split(" ")
      end
  
      #
      # @param [Array,String] value to be converted into the correct format
      # @return [String] the space-delimited string
      #
      def save(value)
        Array(value).join(" ")
      end
      
      #
      # Space Delimited Strings are not unlike arrays and those we assume that the
      # inputs are going to be two arrays that will be joined and then ensured 
      # that only the unique values are saved.
      # 
      # @param [Nil,String] original the original value stored within the field
      # @param [Nil,String,Array] value the new values that will coerced into an array
      #   and joined with the original values.
      #
      def append(original,value)
        save( ( open(original) + Array(value)).uniq )
      end
  
    end
    
  end
end
