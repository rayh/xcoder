module Xcode
  module ConfigurationList
    
    # 
    # @example configuration list
    # 
    #     7165D47D146B4EA100DE2F0E /* Build configuration list for PBXNativeTarget "TestProject" */ = {
    #       isa = XCConfigurationList;
    #       buildConfigurations = (
    #         7165D47E146B4EA100DE2F0E /* Debug */,
    #         7165D47F146B4EA100DE2F0E /* Release */,
    #       );
    #       defaultConfigurationIsVisible = 0;
    #       defaultConfigurationName = Release;
    #     };
    def self.configration_list
      { 'isa' => 'XCConfigurationList',
        'buildConfigurations' => [],
        'defaultConfigurationIsVisible' => '0',
        'defaultConfigurationName' => '' }
    end
    
    #
    # Create a configuration for this ConfigurationList. This configuration needs
    # to have a name.
    # 
    # @note unique names are currently not enforced but likely necessary for the
    #   the target to be build successfully.
    # 
    # @param [Types] name Description
    #
    def create_config(name)
      
      # @todo translate :debug => 'Debug', :release => 'Release'
      
      # @todo a configuration has additional fields that are ususally set with 
      #   some target information for the title.
      
      new_config = @registry.add_object(Configuration.default_properties(name))
      @properties['buildConfigurations'] << new_config.identifier
      
      yield new_config if block_given?
      
      new_config.save!
    end
    
    #
    # @return [BuildConfiguration] the build configuration that is set to default;
    #   nil if no configuration has been set as default.
    # 
    def default_config
      buildConfigurations.find {|config| config.name == defaultConfigurationName }
    end
    
    #
    # @return [String] the name of the default build configuration; nil if no
    #   configuration has been set as default.
    # 
    def default_config_name
      defaultConfigurationName
    end
    
    #
    # @todo allow the ability for a configuration to set itself as default and/or
    #   let a configuration be specified as a parameter here. Though we need
    #   to check to see that the configuration is part of the this configuration
    #   list.
    # 
    # @param [String] name of the build configuration to set as the default 
    #   configuration; specify nil if you want to remove any default configuration.
    #
    def set_default_config(name)
      # @todo ensure that the name specified is one of the available configurations
      @properties['defaultConfigurationName'] = name
    end
    
  end
end