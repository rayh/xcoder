require 'xcode/core_ext/string'

module Xcode
  
  #
  # Resources are not represented as a true entity within an Xcode project.
  # However when traversing through groups, targets, configurations, etc. you will 
  # find yourself interacting with these objects. As they represent a class that
  # acts as a shim around their hash data.
  # 
  # The goal of the {Resource} is to aid in the navigation through the project
  # and provide a flexible system to allow for Xcoder to adapt to changes to 
  # the Xcode project format.
  # 
  # A Resource requires an identifier and an instance of the {Registry}. Based
  # on the supplied identifier, it peforms a look up of it's properties or hash
  # of data. With that hash it then proceeds to create methods that allow for
  # easy read/write access to those property elements. This is similar to Ruby's
  # OpenStruct.
  #
  # @example Accessing the contents of a file reference
  # 
  #     file = project.file('IOSApp/IOSAppDelegate.m').properties # => 
  # 
  #     { 'isa' => 'PBXFileReference',
  #       'lastKnownFileType' => 'sourcecode.c.h',
  #       'path' => IOSAppDelegate.h', 
  #       'sourceTree' => "<group>" }
  # 
  #     file.isa # => 'PBXFileReference'
  #     file.last_known_file_type # => 'sourcecode.c.h'
  #     file.path # => 'IOSAppDelegate.m'
  #     file.path = "NewIOSAppDelegate.m" # => 'NewIOSAppDeleget.m'
  #     file.source_tree # => "<group>"
  #
  # In the above example, you can still gain access to the internal properties
  # through the {#properties} method. However, the {Resource} provides for you
  # additional ruby friendly methods to access the properties.
  # 
  # To provide additional convenience when traversing through the
  # various objects, the getter methods will check to see if the value
  # being returned matches that of a unique identifier. If it does, instead of
  # providing that identifier, it will instead look in the {Registry} for the 
  # object that matches and return a new Resource automatically.
  # 
  # @example Magically accessing resources through resources
  # 
  #     group = project.groups
  #     group.properties # =>
  # 
  #     { "children"=>["7165D45A146B4EA100DE2F0E", 
  #                    "7165D472146B4EA100DE2F0E", 
  #                    "7165D453146B4EA100DE2F0E", 
  #                    "7165D451146B4EA100DE2F0E"], 
  #       "isa"=>"PBXGroup", 
  #       "sourceTree"=>"<group>"}
  # 
  #     group.children.first # => 
  # 
  #     PBXGroup 7165D45A146B4EA100DE2F0E {"children"=>["7165D463146B4EA100DE2F0E", 
  #                                                     "7165D464146B4EA100DE2F0E", 
  #                                                     "7165D45B146B4EA100DE2F0E"], 
  #                                        "isa"=>"PBXGroup", 
  #                                        "path"=>"TestProject", 
  #                                        "sourceTree"=>"<group>"} 
  # 
  # In this example when accessing the first element of children instead of an
  # identifier string being returned the child resource is returned. This
  # functionality is in place to allow Xcoder to flexibly conform to new relationships 
  # that may exist or come to exist.
  # 
  # Lastly, a {Resource} is simply not enough to describe most of the objects
  # within an Xcode project as each object has unique functionality that needs 
  # to be able to perform. So each resource when it is created will query the
  # {Registry#isa_to_module} hash to determine the functionality that it needs
  # to additionally extend into the Resource.
  # 
  # This `isa` property mapped to Ruby modules allows for the easy expansion of
  # new objects or for changes to be made to existing ones as needed.
  # 
  class Resource
    
    # @return [String] the unique identifier for this resource
    attr_accessor :identifier
    
    # The raw properties hash that is known about the resource. This is the best
    # way to manipulate the raw values of the resource.
    # 
    # @return [Hash] the raw properties hash for the object
    attr_accessor :properties
    
    # The registry of all objects within the project file which all resources
    # have a reference to so that they can retrieve any items they may own that
    # are simply referenced by identifiers. This registry is used to convert
    # identifier keys to resource objects. It is also passed to any resources
    # that are created.
    # 
    # @return [Registry] the registry for the entire project.
    attr_reader :registry
    
    #
    # Definiing a property allows the creation of an alias to the actual value.
    # This level of indirection allows for the replacement of values which are
    # identifiers with a resource representation of it.
    # 
    # @note This is used internally by the resource when it is created to create
    #   the getter/setter methods.
    # 
    # @param [String] name of the property
    # @param [String] value of the property
    # 
    def define_property name, value
      
      # Save the properties within the resource within a custom hash. This 
      # provides access to them without the indirection that we are about to
      # set up.
      
      @properties[name] = value
      
      # Generate a getter method for this property based on the given name.
      
      self.class.send :define_method, name.underscore do
        
        # Retrieve the value that is current stored for this name.
        
        raw_value = @properties[name]
        
        # If the value is an array then we want to examine each element within
        # the array to see if any of them are identifiers that we should replace
        # finally returning all of the items as their resource representations
        # or as their raw values.
        # 
        # If the value is not an array then we want to examine that item and
        # return the resource representation or the raw value.
        
        if raw_value.is_a?(Array)
          
          Array(raw_value).map do |sub_value|
            
            if Registry.is_identifier? sub_value 
              Resource.new sub_value, @registry
            else
              sub_value
            end
          end
          
        else 
          
          if Registry.is_identifier? raw_value
            Resource.new raw_value, @registry
          else 
            raw_value
          end
          
        end

      end
      
      # Generate a setter method for this property based on the given name.
      
      self.class.send :define_method, "#{name.underscore}=" do |new_value|
        @properties[name] = new_value
      end
      
      
    end

    #
    # A Resource is created during {Project#initialize}, when the project is
    # first parsed. Afterwards each Resource is usually generated through the 
    # special getter method defined through {#define_property}.
    # 
    # @see Project#initialize
    # @see #defined_property
    # 
    # @param [String] identifier the unique identifier for this resource.
    # @param [Registry] registry the core registry for the system. 
    #
    def initialize identifier, registry
      @registry = registry
      @properties = {}
      @identifier = identifier
      
      # Create property methods for all of the key-value pairs found in the
      # registry for specified identifier.
      
      Array(registry.properties(@identifier)).each do |key,value| 
        send :define_property, key, value
      end
      
      #  
      # Based on the `isa` property find if there is a constant within
      # the Xcode module that matches and if it does, then we want to 
      # automatically include module into the Resource object.
      # 
      constant = Registry.isa_to_module(isa)
        
      self.extend(constant) if constant
      
    end
    
    
    #
    # Saves the current resource back to the registry. This is necessary as
    # any changes made are not automatically saved back into the registry.
    # 
    # @example group adding a files and then saving itself
    # 
    #     group = project.groups
    #     group.create_file 'name' => 'AppDelegate.m', 'path' => 'AppDelegate.m'
    #     group.save!
    # 
    # @return [Resource] the object that is being saved.
    def save!
      @registry.set_object(self)
      self
    end
    
    #
    # @return [String] a representation with the identifier and the properties 
    #   for this resource.
    # 
    def to_s
      "#{isa} #{@identifier} #{@properties}"
    end
    
    #
    # This will generate the resource in the format that is supported by the
    # Xcode project file. Which requires each key value pair to be represented.
    # 
    # @return [String] a string representation of the object so that it can
    #   be persisted to an Xcode project file.
    # 
    def to_xcplist
      %{
        #{@identifier} = { #{ @properties.map {|k,v| "#{k} = \"#{v.to_xcplist}\"" }.join("; ") } }
      }
    end
    
  end
  
end