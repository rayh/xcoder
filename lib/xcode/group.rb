module Xcode
  
  module PBXGroup
    
    attr_accessor :supergroup
    
    def groups
      children.map do |group|
        group.supergroup = self
        group
      end
    end
    
    def group(name)
      groups.find_all {|group| group.name == name }
    end
    
    def add_group(name)
      
      # if this group represents a real path then use 'path'
      # otherwise use 'name'
      
      new_identifier = @registry.add_object 'isa' => 'PBXGroup', 
        'name' => name,
        'sourceTree' => '<group>',
        'children' => []
        
      @properties['children'] << new_identifier
      
      groups.find {|group| group.identifier == new_identifier }
      
    end
    
    def remove!
      @registry.remove_object identifier
      # TODO If this is the main group then we likely don't want to remove it
      # TODO We likely want to remove any references held by other objects
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
      
      children.find {|file| file.identifier == new_identifier }
      
    end
    
  end
  
end