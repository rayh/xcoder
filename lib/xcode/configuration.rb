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
    
    def set_other_linker_flags(value)
      set 'OTHER_LDFLAGS', value
    end
    
    def get(name)
      buildSettings[name]
    end
    
    def set name, value
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