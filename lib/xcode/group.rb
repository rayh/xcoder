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
    # @return [Array<Group>] the groups with the same matching name. This
    #   could be no groups, one group, or multiple groups.
    #
    def group(name)
      groups.find_all {|group| group.name == name }
    end
    
    #
    # Return a single reference that matches the name specified.
    # 
    # @param [String] name of the file that want to return.
    # @return [Group,FileReference] the object that has the name matching the
    #   the one specified.
    # 
    def file(name)
      group(name).first
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
      
      # Groups that represent a physical path often have the key 'path' with
      # the value being it's path name.
      # 
      # Groups that represent a logical group often have the key 'name' with 
      # the value being it's group name.
      
      new_group = @registry.add_object Group.with_properties_for_logical_group(name)
      
      new_group.supergroup = self
      # Add the group's identifier to the list of children
      
      @properties['children'] << new_group.identifier
      
      new_group
    end
    
    # @todo for right now provide add_group but it should be removed as add_group
    #   should likely add an existing group or take a group and not create one.
    alias_method :add_group, :create_group
    
    #
    # Add a file to the specified group. Currently the file creation requires
    # the path to the physical file.
    # 
    # @param [String,Hash] path to the file that is being added or a hash that 
    #   contains the values would be merged with the default values.
    #
    def create_file(file_properties)
      file_properties = { 'path' => file_properties } if file_properties.is_a? String
      
      new_file = @registry.add_object FileReference.file(file_properties)
        
      @properties['children'] << new_file.identifier
      
      new_file
    end
    
    # @todo for right now provide add_file but it should be removed as add_file
    #   should likely add an existing file or take a file and not create one.
    alias_method :add_file, :create_file
    
    
    #
    # Create a framework within this group.
    # 
    # @param [Hash] framework_properties the properties to merge with the default
    #   properties.
    #
    def create_framework(framework_properties)
      new_framework = @registry.add_object FileReference.framework(framework_properties)
      
      @properties['children'] << new_framework.identifier
      
      new_framework
    end
    
    # @todo for right now provide add_framework but it should be removed as add_framework
    #   should likely add an existing file or take a file and not create one.
    alias_method :add_framework, :create_framework
    
    #
    # Create an infoplist within this group.
    # 
    # @param [Hash] infoplist_properties the properties to merge with the default
    #   properties.
    # 
    # @see VariantGroup#info_plist
    #
    def create_infoplist(infoplist_properties)
      new_plist = @registry.add_object VariantGroup.info_plist(infoplist_properties)
      
      @properties['children'] << new_plist.identifier
      
      new_plist
    end
    
  end
  
end