module Xcode
  
  module PBXGroup
    
    def add_group(name)
      
      # if this group represents a real path then use 'path'
      # otherwise use 'name'
      
      new_identifier = @registry.add_object 'isa' => 'PBXGroup', 
        'name' => name,
        'sourceTree' => '<group>',
        'children' => []
        
      @properties['children'] << new_identifier
      
      children.find {|child| child.identifier == new_identifier }
      
    end
    
    def add_file(path)
      
      # {isa = PBXFileReference; 
      # lastKnownFileType = sourcecode.c.h; 
      # path = IOSAppDelegate.h; 
      # sourceTree = "<group>"; };

      new_identifier = @registry.add_object 'isa' => 'PBXFileReference', 
        'path' => path,
        'sourceTree' => '<group>'
        
      @properties['children'] << new_identifier
      
      children.find {|child| child.identifier == new_identifier }
      
    end
    
  end
  
end