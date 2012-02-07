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
      list = { 'isa' => 'XCConfigurationList',
        'buildConfigurations' => [],
        'defaultConfigurationIsVisible' => '0',
        'defaultConfigurationName' => '' }
        
      yield list if block_given?
      
      list
    end
    
  end
end