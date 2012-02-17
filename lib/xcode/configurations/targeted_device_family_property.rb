
module Xcode
  module Configuration

    #
    # Within the a build settings there is a setting for the Targeted Device
    # Family which assigns particular numeric values to the platform types.
    # 
    # Instead of manipulating the numeric values, this will perform a conversion
    # return an array of symbols with the platforms like :iphone and :ipad.
    # 
    module TargetedDeviceFamily
      extend self
      
      #
      # @param [String] value convert the comma-delimited list of platforms
      # @return [Array<Symbol>] the platform names supported.
      #
      def open(value)
        value.to_s.split(",").map do |platform_number|
          platforms[platform_number]
        end
      end
    
      #
      # @param [String,Array<String>] value convert the array of platform names 
      # @return [String] the comma-delimited list of numeric values representing 
      #   the platforms.
      #
      def save(value)
        Array(value).map do |platform_name|
          platforms.map {|number,name| number if name.to_s == platform_name.to_s.downcase }
        end.flatten.compact.uniq.join(",")
      end
      
      #
      # @param [String] original is the current string value stored in the configuration
      #   that needs to be converted into an Array of names.
      # @param [String,Array<String>] value the new values to include in the device
      #   family.
      # 
      def append(original,value)
        save(open(original) + Array(value))
      end
    
      private
  
      def platforms
        { "1" => :iphone, "2" => :ipad }
      end
  
    end

  end
end