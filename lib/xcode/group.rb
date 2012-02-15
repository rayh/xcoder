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
    # @return [Hash] the properties for a Group
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
    # 
    # @return [Array<Resource>] the children of the group, excluding the 
    #   groups, which is usually composed of FileReferences
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
    # Check whether a file or group is contained within this group that has a name
    # that matches the one specified
    # 
    # @param [String] name of the group attempting to be found.
    # 
    # @return [Array<Resource>] resource with the name that matches; empty array 
    #   if no matches were found.
    # 
    def exists?(name)
      children.find_all {|child| child.name == name }
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
    # @return [Group] the created group
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
    # @example creating a file with just a path
    # 
    #     project.main_group.create_file 'AppDelegate.m'
    # 
    # @example creating a file with a name and path
    # 
    #     project.main_group.create_file 'name' => 'AppDelegate.m', 'path' => 'Subfolder/AppDelegate.m'
    # 
    # @param [String,Hash] path to the file that is being added or a hash that 
    #   contains the values would be merged with the default values.
    # 
    # @return [FileReference] the file created.
    # 
    def create_file(file_properties)
      # This allows both support for the string value or the hash as the parameter
      file_properties = { 'path' => file_properties } if file_properties.is_a? String
      
      # IF the file already exists then we will not create the file with the
      # parameters that are being supplied, instead we will return what we
      # found.
      
      find_file_by = file_properties['name'] || file_properties['path']
      found_or_created_file = exists?(find_file_by).first
      
      unless found_or_created_file
        found_or_created_file = create_child_object FileReference.file(file_properties)
      end
      found_or_created_file.supergroup = self
      
      found_or_created_file
    end
    
    #
    # Create a framework within this group.
    # 
    # @example Custom.Framework
    # 
    #     project.frameworks_group.create_framework 'name' => 'Custom.framework', 
    #       'path' => 'Vendor/Custom/Custom.framework' 
    # 
    # @param [Hash] framework_properties the properties to merge with the default
    #   properties.
    #
    # @return [FileReference] the framework created.
    # 
    def create_framework(framework_properties)
      find_or_create_child_object FileReference.framework(framework_properties)
    end
    
    #
    # Create a system framework reference within this group
    # 
    # @example creating 'CoreGraphics' and 'Foundation' frameworks
    # 
    #     project.frameworks_group.create_system_framework "CoreGraphics.framework"
    #     project.frameworks_group.create_system_framework "Foundation"
    #
    # @param [String] name the name of the System framework to add to this group.
    # @return [FileReference] the system framework created.
    # 
    def create_system_framework(name)
      find_or_create_child_object FileReference.system_framework(name)
    end

    #
    # Create a system library reference within this group
    #
    #  @example libz.dylib
    # 
    #     project.frameworks_group.create_system_library "libz.dylib"
    #
    # @param [String] name the name of the System Library to add to this group.
    # @return [FileReference] the system library created.
    # 
    def create_system_library(name)
      find_or_create_child_object FileReference.system_library(name)
    end
    
    #
    # Create an infoplist within this group.
    # 
    # @param [Hash] infoplist_properties the properties to merge with the default
    #   properties.
    # 
    # @see VariantGroup#info_plist
    # @return [VariantGroup] the infoplist created
    # 
    def create_infoplist(infoplist_properties)
      create_child_object VariantGroup.info_plist(infoplist_properties)
    end
    
    #
    # Create a product reference witin this group.
    # 
    # @note this is usually performed through the target as it is necessary within
    #   the target to specify what is the product reference.
    # 
    # @see Target#create_product_reference
    # 
    # @param [String] name the name of the product to generate
    # @return [FileReference] the app product created.
    # 
    def create_product_reference(name)
      create_child_object FileReference.app_product(name)
    end
    
    #
    # Remove the resource from the registry. 
    # 
    # @note all children objects of this group are removed as well.
    # 
    def remove!(&block)
      
      # @note #groups and #files is used because it adds the very precious
      #   supergroup to each of the child items.
      
      groups.each {|group| group.remove!(&block) }
      files.each {|file| file.remove!(&block) }
      yield self if block_given?
      
      child_identifier = identifier
      supergroup.instance_eval { remove_child_object(child_identifier) }
      @registry.remove_object identifier
    end
    
    private
    
    #
    # This method is used internally to add object to the registry and add the
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
    
    #
    # This method is used internally to find the specified object or add the object
    # as a child of this group.
    # 
    # @param [Hash] child_properties the hash of resource to add as a child
    #   object of this group if it does not already exist as a child.
    #
    # @return [Resource] returns the resource that was added a child
    def find_or_create_child_object(child_properties)
      found_child = children.find {|child| child.name == child_properties['name'] or child.path == child_properties['path'] }
      found_child = create_child_object(child_properties) unless found_child
      found_child
    end
    
    #
    # This method is used internally to remove a child object from this and the
    # registry.
    #
    # @param [String] identifier of the child object to be removed.
    # @return [Resource] the removed child resource
    def remove_child_object(identifier)
      found_child = children.find {|child| child.identifier == identifier }
      @properties['children'].delete identifier
      save!
      found_child
    end
    
  end
  
end