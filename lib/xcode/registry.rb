require 'xcode/build_file'
require 'xcode/build_phase'
require 'xcode/configuration'
require 'xcode/configuration_list'
require 'xcode/file_reference'
require 'xcode/group'
require 'xcode/resource'
require 'xcode/project_scheme'
require 'xcode/simple_identifier_generator'
require 'xcode/configuration_owner'
require 'xcode/target'
require 'xcode/variant_group'
require 'xcode/project_reference'
require 'xcode/target_dependency'
require 'xcode/container_item_proxy'

module Xcode
  
  #
  # The Registry represents the parsed data from the Xcode Project file. The 
  # registry is a Hash that provides additional functionality to allow the 
  # the ability to query, add, and remove resources from the object hash.
  # 
  # Opening the Xcode project file in a text-editor you'll notice that it is a
  # big hash/plist. The registry represents this structure and provides access
  # to the top-level items: 'rootObject'; 'objectVersion'; 'archiveVersion' and 
  # 'objects'. The registry provides a number of methods to access these items.
  # 
  # The most important key is the 'objects' dictionary which maintains the 
  # master-list of Identifiers to properties. The registry provides additional
  # methods get, add, remove, and update the objects stored within it. The 
  # registry returns {Resource} objects which is a wrapper class around the 
  # properties hash that would normally be returned. Providing additional 
  # functionality to make it easier to traverse the project.
  # 
  # @see Project
  # 
  module Registry
    
    #
    # This method is used internally to determine if the value that is being 
    # retrieved is an identifier.
    # 
    # @see Resource#define_property
    # 
    # @param [String] value is the specified value in the form of an identifier
    # @return [TrueClass,FalseClass] true if the value specified is a valid 
    #   identifier; false if it is not.
    # 
    def self.is_identifier? value
      value =~ /^[0-9A-F]{24,}$/
    end

    #
    # All object parameters contain an `isa` property, which represents the class
    # within Xcode. Here the `isa` string value is translated into a Ruby module.
    # 
    # Initially the `isa` values were mapped directly to Ruby modules but that
    # was changed to this model to make it easy to repair if Xcode were to 
    # change their `isa` values and also provide the ability to mixin different
    # functionality as needed.
    # 
    # @see Resource#initialize
    # 
    # @param [String] isa the type of the object.
    # @return [Array<Module>] an array of modules that are mapped to the 
    #   string name.
    # 
    def self.isa_to_module isa

      modules = { 'PBXProject' => [ProjectReference, ConfigurationOwner],
        'XCBuildConfiguration' => Configuration,
        'PBXFileReference' => FileReference,
        'PBXGroup' => Group,
        'PBXNativeTarget' => [Target, ConfigurationOwner ],
        'PBXLegacyTarget' => [Target, ConfigurationOwner ],
        'PBXAggregateTarget' => [ Target, ConfigurationOwner ],
        'PBXFrameworksBuildPhase' => BuildPhase,
        'PBXSourcesBuildPhase' => BuildPhase,
        'PBXResourcesBuildPhase' => BuildPhase,
        'PBXHeadersBuildPhase' => BuildPhase,
        'PBXShellScriptBuildPhase' => BuildPhase,
        'PBXTargetDependency' => TargetDependency,
        'PBXContainerItemProxy' => ContainerItemProxy,
        'PBXBuildFile' => BuildFile,
        'PBXVariantGroup' => VariantGroup,
        'XCConfigurationList' => ConfigurationList,
        'PBXVariantGroup' => VariantGroup }[isa]
        
        Array(modules)
    end
    
    #
    # This is the root object of the project. This is generally an identifier
    # pointing to a project.
    # 
    # @return [Resource] this is traditionally the root, project object.
    # 
    def root
      self['rootObject']
    end
    
    
    #
    # This is a hash of all the objects within the project. The keys are the
    # unique identifiers which are 24 length hexadecimal strings. The values
    # are the objects that the keys represent.
    # 
    # @return [Hash] that contains all the objects in the project. 
    # 
    def objects
      self['objects']
    end

    #
    # @return [Fixnum] the object version
    # 
    def object_version
      self['objectVersion'].to_i
    end
    
    #
    # @return [Fixnum] the archive version
    # 
    def archive_version
      self['archiveVersion'].to_i
    end
    
    #
    # Retrieve a Resource for the given identifier.
    # 
    # @param [String] identifier the unique identifier for the resource you are
    #   attempting to find.
    # @return [Resource] the Resource object the the data properties that would
    #   be stored wihin it.
    # 
    def object(identifier)
      Resource.new identifier, self
    end
    
    #
    # Retrieve the properties Hash for the given identifer. 
    #
    # @param [String] identifier the unique identifier for the resource you
    #   are attempting to find.
    # 
    # @return [Hash] the raw, properties hash for the particular resource; nil 
    #   if nothing matches the identifier.
    #
    def properties(identifier)
      objects[identifier]
    end
    
    #
    # Provides a method to generically add objects to the registry. This will
    # create a unqiue identifier and add the specified parameters to the 
    # registry. As all objecst within a the project maintain a reference to this
    # registry they can immediately query for newly created items.
    # 
    # @note generally this method should not be called directly and instead 
    #   resources should provide the ability to assist with generating the 
    #   correct objects for the registry.
    # 
    # @param [Hash] object_properties a hash that contains all the properties
    #   that are known for the particular item.
    # 
    def add_object(object_properties)
      new_identifier = SimpleIdentifierGenerator.generate :existing_keys => objects.keys
      
      objects[new_identifier] = object_properties
      
      Resource.new new_identifier, self
    end

    #
    # Replace an existing object that shares that same identifier. This is how
    # a Resource is saved back into the registry. So that it will be known to 
    # all other objects that it has changed.
    # 
    # @see Resource#save!
    # 
    # @param [Resource] resource the resource that you want to set at the specified
    #   identifier. If an object exists at that identifier already it will be 
    #   replaced.
    #
    def set_object(resource)
      objects[resource.identifier] = resource.properties
    end

    #
    # @note removing an item from the regitry does not remove all references
    #   to the item within the project. At this time, this could leave resources
    #   with references to resources that are invalid.
    # 
    # @param [String] identifier of the object to remove from the registry.
    #
    def remove_object(identifier)
      objects.delete identifier
    end
    
  end
end
