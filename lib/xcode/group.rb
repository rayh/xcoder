module Xcode
  
  #
  # Within the project file there are logical separation of resources into groups
  # these groups may contain subgroups, files, or other objects. They have
  # children.
  # 
  # PBXGroup here provides the methods to traverse the groups to find these 
  # children resources as well as provide the ability to generate child
  # resources.
  # 
  module Group
    
    #
    # Return the hash that maps to the properties for a logical group
    # 
    # @param [String] name of the logical group
    # 
    def self.with_properties_for_logical_group(name)
      { 'isa' => 'PBXGroup', 
        'name' => name,
        'sourceTree' => '<group>',
        'children' => [] }
    end
    
    
    # This is the group for which this file is contained within.
    attr_accessor :supergroup
    
    # 
    # @example Return all the sub-groups of the main group
    # 
    #   main_group = Xcode.project('MyProject.xcodeproj').groups
    #   main_group.groups
    # 
    # @return [Array] the sub-groups contained within this group.
    # 
    def groups
      children.map do |group|
        # TODO: this will return all children when it should just return subgroups
        group.supergroup = self
        group
      end
    end
    
    #
    # Find all the child groups that have a name that matches the specified name.
    # 
    # @param [String] name of the group that you are looking to return.
    # @return [Array<PBXGroup>] the groups with the same matching name. This
    #   could be no groups, one group, or multiple groups.
    #
    def group(name)
      groups.find_all {|group| group.name == name }
    end
    
    
    #
    # Adds a group as a child to current group with the given name. 
    # 
    # @note A group may be added that has the same name as another group as they
    #   are distinguished by a unique identifier and not by name.
    # 
    # @param [String] name of the group that you want to add as a child group of
    #   the specified group.
    #
    def add_group(name)
      
      # Groups that represent a physical path often have the key 'path' with
      # the value being it's path name.
      # 
      # Groups that represent a logical group often have the key 'name' with 
      # the value being it's group name.
      
      new_identifier = @registry.add_object Group.with_properties_for_logical_group(name)
      
      # Add the group's identifier to the list of children
      
      @properties['children'] << new_identifier
      
      # Find the newly added group to return
      
      groups.find {|group| group.identifier == new_identifier }
      
    end
    
    #
    # Add a file to the specified group. Currently the file creation requires
    # the path to the physical file.
    # 
    # @param [String] path to the file that is being added.
    #
    def add_file(path)
      
      new_identifier = @registry.add_object FileReference.with_properties_for_path(path)
        
      @properties['children'] << new_identifier
      
      children.find {|file| file.identifier == new_identifier }
      
    end
    
    
    def add_framework framework_name
      new_identifier = @registry.add_object FileReference.with_properties_for_framework(framework_name)
      
      # Add the framework to the group
      
      @properties['children'] << new_identifier
      
      children.find {|file| file.identifier == new_identifier }
      
    end
    
    
  end
  
end