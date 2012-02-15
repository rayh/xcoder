require_relative 'group'

module Xcode
  
  #
  # A VariantGroup is generally a special group reserved for InfoPlist.strings
  # folders that contain additional files within it that are referenced.
  # 
  module VariantGroup
    include Group ; extend Group
    
    #
    # # E21EB9DE14E357CF0058122A /* InfoPlist.strings */ = {
    #       isa = PBXVariantGroup;
    #       children = (
    #         E21EB9DF14E357CF0058122A /* en */,
    #       );
    #       name = InfoPlist.strings;
    #       sourceTree = "<group>";
    #     };
    # 
    def self.info_plist properties
      default_properties = { 'isa' => 'PBXVariantGroup',
        'children' => [],
        'name' => name,
        'sourceTree' => '<group>' }
        
      default_properties.merge(properties)
    end
    
  end
end