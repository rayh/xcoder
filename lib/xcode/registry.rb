require 'xcode/simple_identifier_generator'

module Xcode
  
  #
  # The Registry represents the parsed data from the Xcode Project file. Namely
  # the registry is a Hash that provides additional functionality to allow the 
  # the ability to query, add, and remove resources from the object hash.
  # 
  # Opening the Xcode project file in a text-editor you'll notice that it is a
  # big hash/plist with a file core keys. The most important key is the 'objects'
  # dictionary which maintains the master-list of Identifiers to properties. All 
  # objects are represented here and all other resources use the reference
  # to make the connection to the objects.
  # 
  # @see Project
  # 
  module Registry
    
    #
    # This method is used internally to determine if the value that is being 
    # retrieved is an identifier.
    # 
    # @param [String] value is the specified value in the form of an identifier
    #
    def self.is_identifier? value
      value =~ /^[0-9A-F]{24}$/
    end

    #
    # Objects within the registry contain an `isa` property, which translates
    # to modules which can be mixed in to provide additional functionality.
    # 
    # @param [String] isa the type of the object.
    #
    def self.isa_to_module isa

      { 'XCBuildConfiguration' => Configuration,
        'PBXFileReference' => FileReference,
        'PBXGroup' => Group,
        'PBXNativeTarget' => Target,
        'PBXAggregateTarget' => Target,
        'PBXFrameworksBuildPhase' => BuildPhase,
        'PBXSourcesBuildPhase' => BuildPhase,
        'PBXResourcesBuildPhase' => BuildPhase,
        'PBXBuildFile' => BuildFile,
        'PBXVariantGroup' => VariantGroup,
        'XCConfigurationList' => ConfigurationList,
        'PBXVariantGroup' => VariantGroup }[isa]
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
    
    MAX_IDENTIFIER_GENERATION_ATTEMPTS = 10
    
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
      
      new_identifier = SimpleIdentifierGenerator.generate
      
      # Ensure that the identifier generated is unique
      
      identifier_generation_count = 0
      
      while objects.key?(new_identifier)
        
        new_identifier = SimpleIdentifierGenerator.generate
        
        # Increment our identifier generation count and if we reach our max raise
        # an exception as something has gone horribly wrong.

        identifier_generation_count += 1
        if identifier_generation_count > MAX_IDENTIFIER_GENERATION_ATTEMPTS
          raise "Unable to generate a unique identifier for object: #{object_properties}"
        end
      end
      
      new_identifier = SimpleIdentifierGenerator.generate if objects.key?(new_identifier)
      
      
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
