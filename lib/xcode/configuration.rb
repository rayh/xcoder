require 'xcode/builder'
require 'xcode/configurations/space_delimited_string_property'
require 'xcode/configurations/targeted_device_family_property'
require 'xcode/configurations/string_property'
require 'xcode/configurations/boolean_property'
require 'xcode/configurations/array_property'
require 'xcode/configurations/key_value_array_property'

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
    
    #
    # A large number of these default build settings properties for a configuration 
    # are as defined for Xcode 4.2.
    # 
    # @todo remove the name requirement and replace all these configuration settings
    #   with the smaller subset. As a lot of these are usually maintained by the project
    # @param [String] name is used to create the correct prefix header file and 
    #   info.plist file.
    # @return [Hash] properties for a default build configuration
    # 
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
        
        # When the build setting is missing from the existing configuration, look
        # for the configuration of the target's project (only if we are currently
        # at the Target level).
        
        if not build_settings.key?(setting_name) and target.is_a?(Target)
          project_config = target.project.global_config(name)
          project_config.send(property_name)
        else
          substitute type.open(build_settings[setting_name])
        end
        
      end

      # Define a setter method
      
      define_method "#{property_name}=" do |value|
        build_settings[setting_name] = unsubstitute(type.save(value))
      end

      # Define an append method
      
      define_method "append_to_#{property_name}" do |value|
        build_settings[setting_name] = unsubstitute type.append(build_settings[setting_name],value)
      end
      
      # Define a environment name method (to return the settings name)
      
      define_method "env_#{property_name}" do
        setting_name
      end
      
      # Define a raw getter
      
      define_method "raw_#{property_name}" do
        build_settings[setting_name]
      end
      
      # Define a raw setter
      
      define_method "raw_#{property_name}=" do |value|
        build_settings[setting_name] = value
      end
      
      
      @setting_name_to_property = {} unless @setting_name_to_property
      @setting_name_to_property[setting_name] = property_name
      
    end
    
    def self.setting_name_to_property(name)
      @setting_name_to_property[name]
    end
    
    #
    # As configurations are defined within a target, this will return the target
    # that owns this configuration through a build_configuration list.
    # 
    # However, a build configuration list can also be defined at the project level
    # which means target may likely be nil when viewing the configuration of
    # the project.
    # 
    # @see Target
    # @see ConfigurationList
    # 
    attr_accessor :target

    # @attribute
    # Build Setting - "PRODUCT_NAME"
    property :product_name, "PRODUCT_NAME", StringProperty

    # @attribute
    # Build Setting - "SUPPORTED_PLATFORMS"
    property :supported_platforms, "SUPPORTED_PLATFORMS", SpaceDelimitedString

    # @attribute
    # Build Setting - "GCC_PRECOMPILE_PREFIX_HEADER"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW11
    property :precompile_prefix_headers, "GCC_PRECOMPILE_PREFIX_HEADER", BooleanProperty

    # @attribute
    # Build Setting - "GCC_PREFIX_HEADER"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW12
    property :prefix_header, "GCC_PREFIX_HEADER", StringProperty
    
    # @attribute
    # Build Setting - "INFOPLIST_FILE"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW68
    property :info_plist_location, "INFOPLIST_FILE", StringProperty

    # @attribute
    # Build Setting - "WRAPPER_EXTENSION"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW3
    property :wrapper_extension, "WRAPPER_EXTENSION", StringProperty
    
    # @attribute
    # Build Setting - "TARGETED_DEVICE_FAMILY"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW165
    property :targeted_device_family, "TARGETED_DEVICE_FAMILY", TargetedDeviceFamily

    # @attribute
    # Build Setting - "SDKROOT"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW89
    property :sdkroot, "SDKROOT", StringProperty
    
    # @attribute
    # Build Setting - "OTHER_CFLAGS"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW17
    property :other_c_flags, "OTHER_CFLAGS", KeyValueArrayProperty

    # @attribute
    # Build Setting - "GCC_C_LANGUAGE_STANDARD"
    # Usually set to gnu99
    property :c_language_standard, "GCC_C_LANGUAGE_STANDARD", StringProperty
    
    # @attribute
    # Build Setting - "ALWAYS_SEARCH_USER_PATHS"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW110
    property :always_search_user_paths, "ALWAYS_SEARCH_USER_PATHS", BooleanProperty
    
    # @attribute
    # Build Setting - "GCC_VERSION"
    # @see https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW15
    property :gcc_version, "GCC_VERSION", StringProperty

    # @attribute
    # Build Setting - "ARCHS"
    # @see https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW62
    property :architectures, "ARCHS", SpaceDelimitedString

    # @attribute
    # Build Setting - "GCC_WARN_ABOUT_MISSING_PROTOTYPES"
    # Defaults to YES
    property :warn_about_missing_prototypes, "GCC_WARN_ABOUT_MISSING_PROTOTYPES", BooleanProperty

    # @attribute
    # Build Setting - "GCC_WARN_ABOUT_MISSING_PROTOTYPES"
    # @see https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW123
    property :warn_about_return_type, "GCC_WARN_ABOUT_RETURN_TYPE", BooleanProperty

    # @attribute
    # Build Setting - "CODE_SIGN_IDENTITY[sdk=>iphoneos*]"
    # @see https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-DontLinkElementID_10
    property :code_sign_identity, "CODE_SIGN_IDENTITY[sdk=>iphoneos*]", StringProperty

    # @attribute
    # Build Setting - "VALIDATE_PRODUCT"
    # @see https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW167
    property :validate_product, "VALIDATE_PRODUCT", BooleanProperty

    # @attribute
    # Build Setting - "IPHONEOS_DEPLOYMENT_TARGET"
    # @see https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW156
    # @todo this should be a numeric scale from 2.0 through 5.0; at the levels specified in the documentation
    property :iphoneos_deployment_target, "IPHONEOS_DEPLOYMENT_TARGET", StringProperty
    
    # @attribute
    # Build Setting - "COPY_PHASE_STRIP"
    # @see https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW144
    property :copy_phase_strip, "COPY_PHASE_STRIP", BooleanProperty
    
    # @attribute
    # Build Setting - "OTHER_LDFLAGS"
    # @see https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW76
    property :other_linker_flags, "OTHER_LDFLAGS", SpaceDelimitedString
    
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
    
    # @attribute
    # Build Setting - "USER_HEADER_SEARCH_PATHS"
    # @see https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW21
    property :user_header_search_paths, "USER_HEADER_SEARCH_PATHS", SpaceDelimitedString
    
    #
    # Retrieve the configuration value for the given name
    #
    # @param [String] name of the configuration settings to return
    # @return [String,Array,Hash] the value stored for the specified configuration
    #  
    def get(name)
      if Configuration.setting_name_to_property(name)
        send Configuration.setting_name_to_property(name)
      else
        build_settings[name]
      end
    end
    
    #
    # Set the configuration value for the given name
    #
    # @param [String] name of the the configuration setting
    # @param [String,Array,Hash] value the value to store for the specific setting
    #
    def set(name, value)
      if Configuration.setting_name_to_property(name)
        send("#{Configuration.setting_name_to_property(name)}=",value)
      else
        build_settings[name] = value
      end
    end
    
    #
    # Append a value to the the configuration value for the given name
    #
    # @param [String] name of the the configuration setting
    # @param [String,Array,Hash] value the value to store for the specific setting
    #
    def append(name, value)
      if Configuration.setting_name_to_property(name)
        send("append_to_#{Configuration.setting_name_to_property(name)}",value)
      else

        # @note this will likely raise some errors if trying to append a string
        #   to an array, but that likely means a new property should be defined.
  
        if build_settings[name].is_a?(Array)
          # Ensure that we are appending an array to the array; Array() does not
          # work in this case in the event we were to pass in a Hash.
          value = value.is_a?(Array) ? value : [ value ]
          build_settings[name] = build_settings[name] + value
        else
          # Ensure we handle the cases where a nil value is present that we append
          # correctly to the value.
          build_settings[name] = build_settings[name].to_s + value.to_s
        end
       
      end
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
    # @todo move this to a decorator that wraps the other objects that load/save
    #   properties 
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
    # @todo move this to a decorator that wraps the other objects that load/save
    #   properties 
    #
    def unsubstitute(value)
      value
    end

  end
end
