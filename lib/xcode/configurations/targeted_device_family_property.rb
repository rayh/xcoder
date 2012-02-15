
module Xcode
  module Configuration

    #
    # Within the a build settings there is a setting for the Targeted Device
    # Family which assigns particular numeric values to the platform types.
    # 
    # Instead of manipulating the numeric values, this will perform a conversion
    # return an array of names like 'iPhone' and 'iPad'.
    # 
    module TargetedDeviceFamily
      extend self
      
      #
      # @param [String] value convert the comma-delimited list of platforms
      # @return [Array<String>] the platform names supported.
      #
      def open(value)
        value.split(",").map do |platform_number|
          platforms[platform_number]
        end
      end
    
      #
      # @param [Array<String>] value convert the array of platform names 
      # @return [String] the comma-delimited list of numeric values representing 
      #   the platforms.
      #
      def save(value)
        Array(value).map do |platform_name|
          platforms.map {|number,name| number if name == platform_name }
        end.flatten.join(",")
      end
  
      private
  
      def platforms
        { 1 => 'iPhone', 2 => 'iPad' }
      end
  
    end

  end
end