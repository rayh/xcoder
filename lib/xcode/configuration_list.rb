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
    
    def create_config(name)
      
      # translate :debug => 'Debug', :release => 'Release'
      
      # @todo a configuration has additional fields that are ususally set with 
      #   some target information for the title.
      config_identifier = @registry.add_object(Configuration.default_properties(name))
      @properties['buildConfigurations'] << config_identifier
      
      config = buildConfigurations.find {|config| config.identifier == config_identifier }
      
      yield config if block_given?
      
      config.save!
    end
    
    def set_default_configuration(name)
      # @todo ensure that the name specified is one of the available configurations
      @properties['defaultConfigurationName'] = name
    end
    
  end
end