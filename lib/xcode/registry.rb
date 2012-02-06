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
    # @todo this should likely be moved to the Regsitry which knows much more
    #   about identifiers and what makes them valid.
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
        'PBXFrameworksBuildPhase' => BuildPhase }[isa]
      
    end
    
    #
    # This is the root object of the project. This is generally an identifier
    # pointing to a project.
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
    # 
    # @return [String] the object associated with this identifier; nil if no 
    #   object matches the identifier.
    # 
    def object(identifier)
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
      # define a new group within the object list
      # add it as a child
      
      range = ('A'..'F').to_a + (0..9).to_a
      
      new_identifier = 24.times.inject("") {|ident| "#{ident}#{range.sample}" }
      
      # TODO ensure identifier does not collide with other identifiers
      
      objects[new_identifier] = object_properties
      
      new_identifier
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