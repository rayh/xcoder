module Xcode
  
  module PBXGroup
    
    def add_group(name)
      
      # define a new group within the object list
      # add it as a child
      
      require 'digest/md5'
      
      new_identifier = Digest::MD5.hexdigest(Time.now.to_s).upcase[0..23]
      
      # if this group represents a real path then use 'path'
      # otherwise use 'name'
      
      @registry['objects'][new_identifier] = { 'isa' => 'PBXGroup', 
        'name' => name,
        'sourceTree' => '<group>',
        'children' => [] }
        
      @properties['children'] << new_identifier
      
      children.find {|child| child.identifier == new_identifier }
      
    end
    
    
  end
  
end