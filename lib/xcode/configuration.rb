require 'xcode/builder'
require 'xcode/configurations/space_delimited_string'
require 'xcode/configurations/targeted_device_family'
require 'xcode/configurations/string_property'
require 'xcode/configurations/boolean_property'

module Xcode
  
  #
  # Projects have a number of build configurations. These configurations are 
  # usually the default 'Debug' and 'Release'. However, custom ones can be 
  # defined.
  # 
  # @see https://developer.apple.com/library/ios/#documentation/ToolsLanguages/Conceptual/Xcode4UserGuide/Building/Building.html
  # 
  # Each configuration is defined and then a reference of that configuration is
  # maintained in the Target through the XCConfigurationList.
  # 
  # @example Xcode configuration
  #                                                                
  #     E21D8ABB14E0F817002E56AA /* Debug */ = {                     
  #       isa = XCBuildConfiguration;                                
  #       buildSettings = {                                          
  #         "CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
  #         GCC_PRECOMPILE_PREFIX_HEADER = YES;                      
  #         GCC_PREFIX_HEADER = "newtarget/newtarget-Prefix.pch";    
  #         INFOPLIST_FILE = "newtarget/newtarget-Info.plist";       
  #         PRODUCT_NAME = "$(TARGET_NAME)";                         
  #         WRAPPER_EXTENSION = app;                                 
  #       };                                                         
  #       name = Debug;                                              
  #     };                                                           
  # 
  module Configuration
    
    def self.default_properties(name)
      { 'isa' => 'XCBuildConfiguration',
        'buildSettings' => {
          "SDKROOT" => "iphoneos",
          "OTHER_CFLAGS" => "-DNS_BLOCK_ASSERTIONS=1",
          "TARGETED_DEVICE_FAMILY" => "1,2",
          "GCC_C_LANGUAGE_STANDARD" => "gnu99",
          "ALWAYS_SEARCH_USER_PATHS" => "NO",
          "GCC_VERSION" => "com.apple.compilers.llvm.clang.1_0",
          "ARCHS" => "$(ARCHS_STANDARD_32_BIT)",
          "GCC_WARN_ABOUT_MISSING_PROTOTYPES" => "YES",
          "GCC_WARN_ABOUT_RETURN_TYPE" => "YES",
          "CODE_SIGN_IDENTITY[sdk=>iphoneos*]" => "iPhone Developer",
          "GCC_PRECOMPILE_PREFIX_HEADER" => "YES",
          "VALIDATE_PRODUCT" => "YES",
          "IPHONEOS_DEPLOYMENT_TARGET" => "5.0",
          "COPY_PHASE_STRIP" => "YES",
          "GCC_PREFIX_HEADER" => "#{name}/#{name}-Prefix.pch",
          "INFOPLIST_FILE" => "#{name}/#{name}-Info.plist",
          "PRODUCT_NAME" => "$(TARGET_NAME)",
          "WRAPPER_EXTENSION" => "app" },
          "name" => name }
    end
    
    #
    # This method will define getters/setters mapped to the build configuration.
    # 
    # This allows for dynamic values to be saved and loaded by allowing a parsing
    # process to take place on the loaded value and when saving back to the value.
    #
    # @param [Symbol] property_name the name of the property that is being defined
    # @param [String setting_name the configuration value string
    # @param [Types] type is the class that is used to load and save the value
    #   correctly.
    # 
    def self.property(property_name,setting_name,type)
      
      # Define a getter method

      define_method property_name do
        substitute type.open(build_settings[setting_name])
      end

      # Define a setter method
      
      define_method "#{property_name}=" do |value|
        build_settings[setting_name] = unsubstitute(type.save(value))
      end
      
    end
    
    #
    # The configuration is defined within a target.
    # @see Target
    # 
    attr_accessor :target

    property :product_name, "PRODUCT_NAME", StringProperty
    
    property :supported_platforms, "SUPPORTED_PLATFORMS", SpaceDelimitedString
    
    property :precompile_prefiex_headers, "GCC_PRECOMPILE_PREFIX_HEADER", BooleanProperty
    
    property :prefix_header, "GCC_PREFIX_HEADER", StringProperty
    
    property :info_plist_location, "INFOPLIST_FILE", StringProperty
    
    property :wrapper_extension, "WRAPPER_EXTENSION", StringProperty
    
    property :targeted_device_family, "TARGETED_DEVICE_FAMILY", TargetedDeviceFamily
    
    #
    # Opens the info plist associated with the configuration and allows you to 
    # edit the configuration.
    # 
    # @example Editing the configuration
    # 
    #     config = Xcode.project('MyProject.xcodeproj').target('Application').config('Debug')
    #     config.info_plist do |plist|
    #       puts plist.version  # => 1.0
    #       plist.version = 1.1
    #       marketing_version = 12.1
    #     end
    # 
    # @see InfoPlist
    # 
    def info_plist
      info = Xcode::InfoPlist.new(self, info_plist_location)  
      yield info if block_given?
      info.save
      info
    end
    
    property :user_header_search_paths, "USER_HEADER_SEARCH_PATHS", SpaceDelimitedString
    
    #
    # Retrieve the configuration value for the given name
    #
    # @param [String] name of the configuration settings to return
    # @return [String,Array,Hash] the value stored for the specified configuration
    #  
    def get(name)
      build_settings[name]
    end
    
    #
    # Set the configuration value for the given name
    #
    # @param [String] name of the the configuration setting
    # @param [String,Array,Hash] value the value to store for the specific setting
    #
    def set(name, value)
      build_settings[name] = value
    end
    
    #
    # Create a builder for this given project->target->configuration.
    # 
    # @return [Builder] this is a builder for the configuration.
    # @see Builder
    # 
    def builder
      Xcode::Builder.new(self)
    end
    
    private
    
    #
    # Within the configuration properties variables reference the target,
    # i.e."$(TARGET_NAME)". This method will find and replace the target
    # constant with the appropriate value.
    # 
    # @param [String] value is a property of the configuration that may contain
    #   the target variable to replace.
    # 
    # @return [String] a string without the variable reference.
    #
    def substitute(value)
      if value=~/\$\(.*\)/
        value.gsub(/\$\((.*)\)/) do |match|
          case match
            when "$(TARGET_NAME)"
              @target.name 
            else
              raise "Unknown substitution variable #{match}"
          end
        end
      else
        value
      end
    end
    
    #
    # @todo currently this performs no operation, but perhaps it should
    #   in the future to support the ability to persist intelligently back with
    #   paths
    # 
    # @param [Object] value the object that is scanned to figure out if it 
    #   should have content values replaced with environment variables
    #
    def unsubstitute(value)
      value
    end

  end
end
