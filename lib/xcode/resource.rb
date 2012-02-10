
module Xcode
  
  #
  # Resources are not represented as a true entity within an Xcode project.
  # When traversing through groups, targets, configurations, etc. you will find
  # yourself interacting with these objects. As they represent a class that
  # acts as a shim around the hash data is parsed from the project.
  # 
  # A resource do some things that should be explained:
  # 
  # When a resource is created it requires an identifier and an instance of
  # of the Registry. It finds the properties hash of that given identifier 
  # within the registry and creates a bunch of read-only methods that allow for 
  # easy access to those elements. This is not unlike an OpenStruct.
  # 
  # @example of accessing the contents of a file reference
  # 
  #     file_resource.properties # => 
  # 
  #     { 'isa' => 'PBXFileReference',
  #       'lastKnownFileType' => 'sourcecode.c.h',
  #       'path' => IOSAppDelegate.h', 
  #       'sourceTree' => "<group>" }
  # 
  #     file_resource.isa # => 'PBXFileReference'
  #     file_resource.sourceTree # => "<group>"
  #
  # 
  # To provide additional convenience when traversing through the
  # various objects, the read-only method will check to see if the value
  # being returned matches that of a unique identifier. If it does, instead of
  # providing that identifier as a result and then having additional code to
  # perform the look up, it does it automatically.
  # 
  # @example of how this would have to been done without this indirection
  # 
  #     project = Xcode.project('MyProject')
  #     main_group = project.groups
  #     child_identifier = group.children.first
  #     subgroup = project.registry['objects'][child_identifier]
  #     
  # @example of hot this works currently because of this indirection
  # 
  #     group = Xcode.project('MyProject.xcodeproj').mainGroup
  #     subgroup = group.group('Models')
  # 
  # 
  # Next, as most every one of these objects is a Hash that contain the properties
  # instead of objects it would likely be better to encapsulate these resources
  # within specific classes that provide additional functionality. So that when 
  # a group resource or a file resource is returned you can perform unique 
  # functionality with it automatically.
  # 
  # This is done by using the 'isa' property field which contains the type of
  # content object. Instead of creating an object and encapsulating if a module
  # that matches the name of the 'isa', that module of functionality is 
  # automatically mixed-in to provide that functionality.
  # 
  class Resource
    
    # The unique identifier for this resource
    attr_accessor :identifier
    
    # The properties hash that is known about the resource
    attr_accessor :properties
    
    # The registry of all objects within the project file which all resources
    # have a reference to so that they can retrieve any items they may own that
    # are simply referenced by identifiers.
    attr_accessor :registry
    
    #
    # Definiing a property allows the creation of an alias to the actual value.
    # This level of indirection allows for the replacement of values which are
    # identifiers with a resource representation of it.
    # 
    # @note This is used internally by the resource when it is created.
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
      
      self.class.send :define_method, name do
        
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
      
      self.class.send :define_method, "#{name}=" do |new_value|
        @properties[name] = new_value
      end
      
      
    end

    #
    # Within the code, a single resource is created and that is with the root
    # projet object. All other resources are created through the indirecation of
    # the above property methods.
    # 
    # @param [String] identifier the unique identifier for this resource.
    # @param [Types] details Description
    #
    def initialize identifier, details
      @registry = details
      @properties = {}
      @identifier = identifier
      
      # Create property methods for all of the key-value pairs found in the
      # registry for specified identifier.
      
      Array(details.properties(@identifier)).each do |key,value| 
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