require 'xcode/builder'

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
    # The configuration is defined within a target.
    # @see PBXNativeTarget
    # 
    attr_accessor :target
    
    #
    # @return the location for the InfoPlist file for the configuration.
    # @see InfoPlist
    # 
    def info_plist_location
      buildSettings['INFOPLIST_FILE']
    end
    
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

    
    #
    # @return the name of the product that this configuration will generate.
    # 
    def product_name
      substitute(buildSettings['PRODUCT_NAME'])
    end
    
    #
    # Retrieve the configuration value for the given name
    #
    # @param [String] name of the configuration settings to return
    # @return [String,Array,Hash] the value stored for the specified configuration
    #  
    def get(name)
      buildSettings[name]
    end
    
    #
    # Set the configuration value for the given name
    #
    # @param [String] name of the the configuration setting
    # @param [String,Array,Hash] value the value to store for the specific setting
    #
    def set(name, value)
      buildSettings[name] = value
    end
    
    
    #
    # Create a builder for this given project->target->configuration.
    # 
    # @return [Builder] this is a builder for the configuration.
    # @see Builder
    # 
    def builder
      puts "Making a Builder with #{self} #{self.methods}"
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
    
  end
end