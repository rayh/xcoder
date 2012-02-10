module Xcode
  
  #
  # Within the project file there are logical separation of resources into groups
  # these groups may contain subgroups, files, or other objects. They have
  # children.
  # 
  # Group here provides the methods to traverse the groups to find these 
  # children resources as well as provide the ability to generate child
  # resources.
  # 
  #     7165D451146B4EA100DE2F0E /* Products */ = {
  #       isa = PBXGroup;
  #       children = (
  #         7165D450146B4EA100DE2F0E /* TestProject.app */,
  #         7165D46B146B4EA100DE2F0E /* TestProjectTests.octest */,
  #         E21EB9D614E357CF0058122A /* Specs.app */,
  #       );
  #       name = Products;
  #       sourceTree = "<group>";
  #     };
  # 
  module Group
    
    #
    # Return the hash that maps to the properties for a logical group
    # 
    # @param [String] name of the logical group
    # 
    def self.logical_group(name)
      { 'isa' => 'PBXGroup', 
        'name' => name,
        'sourceTree' => '<group>',
        'children' => [] }
    end
    
    
    # This is the group for which this file is contained within.
    # @note this value is only set if the group has been discovered 
    #   by traversing groups to this group.
    attr_accessor :supergroup
    
    # 
    # @example Return all the sub-groups of the main group
    # 
    #     main_group = Xcode.project('MyProject.xcodeproj').groups
    #     main_group.groups
    # 
    # @return [Array] the sub-groups contained within this group.
    # 
    def groups
      children.find_all {|child| child.is_a?(Group) }.map do |group|
        group.supergroup = self
        group
      end
    end
    
    #
    # Find all the child groups that have a name that matches the specified name.
    # 
    # @param [String] name of the group that you are looking to return.
    # @return [Array<Group>] the groups with the same matching name. This
    #   could be no groups, one group, or multiple groups.
    #
    def group(name)
      groups.find_all {|group| group.name == name or group.path == name }
    end
    
    #
    # Find all the non-group objects within the group and return them
    # @return [Array] the children of the group, excluding the groups
    # 
    def files
      children.reject {|child| child.is_a?(Group) }
    end
    
    #
    # Find all the files that have have a name that matches the specified name.
    #
    # @param [String] name of the file that you are looking to return.
    # @return [Array<FileReference>] the files with the same mathching
    #   name. This could be no files, one file, or multiple files.
    #
    def file(name)
      files.find_all {|file| file.name == name or file.path == name }
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
    def create_group(name)
      new_group = create_child_object Group.logical_group(name)
      new_group.supergroup = self
      new_group
    end
    
    #
    # Add a file to the specified group. Currently the file creation requires
    # the path to the physical file.
    # 
    # @param [String,Hash] path to the file that is being added or a hash that 
    #   contains the values would be merged with the default values.
    #
    def create_file(file_properties)
      # This allows both support for the string value or the hash as the parameter
      file_properties = { 'path' => file_properties } if file_properties.is_a? String
      create_child_object FileReference.file(file_properties)
    end
    
    #
    # Create a framework within this group.
    # 
    # @param [Hash] framework_properties the properties to merge with the default
    #   properties.
    #
    def create_framework(framework_properties)
      create_child_object FileReference.framework(framework_properties)
    end
    
    def create_system_framework(name)
      create_child_object FileReference.system_framework(name)
    end
    
    #
    # Create an infoplist within this group.
    # 
    # @param [Hash] infoplist_properties the properties to merge with the default
    #   properties.
    # 
    # @see VariantGroup#info_plist
    #
    def create_infoplist(infoplist_properties)
      create_child_object VariantGroup.info_plist(infoplist_properties)
    end
    
    private
    
    #
    # This method is used internally to add objects to the registry and add the
    # object as a child of this group.
    # 
    # @param [Hash] child_as_properties the hash of resource to add as a child
    #   object of this group.
    # 
    # @return [Resource] returns the resource that was added a child
    def create_child_object(child_properties)
      child_object = @registry.add_object child_properties
      @properties['children'] << child_object.identifier
      child_object
    end
    
  end
  
end