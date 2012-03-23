module Xcode
  
  #
  # Within the project file the FileReference represents a large number of objects
  # related to files like source files, resources, frameworks, and system libraries.
  # 
  # A FileReference is used as input to add to the various Build Phases.
  # 
  # @see BuildPhase 
  # @see BuildFile
  # 
  module FileReference
    
    # This is the group for which this file is contained within.
    # @return [Group] the group that contains this file.
    attr_accessor :supergroup
    
    #
    # Generate the properties for a file. A name and a path option need to
    # be specified in the properties.
    # 
    # @note a 'name' and 'path' key need to be specified in the framework for
    #   the framework to be added correctly.
    # 
    # @param [Hash] properties to override or merge with the base properties.
    # @return [Hash] properties of a file
    #
    def self.file(properties)
      default_properties = { 'isa' => 'PBXFileReference', 
        'path' => nil,
        'sourceTree' => '<group>' }
  
      default_properties.merge(properties)
    end
    
    #
    # Generate the properties for a framework. A name and a path option need
    # to be specified in the properties
    # 
    # @note a 'name' and 'path' key need to be specified in the framework for
    #   the framework to be added correctly.
    # 
    # @param [Hash] properties to override for the Framework
    # @return [Hash] properties for a framework
    #
    def self.framework(properties)
      default_properties = { 'isa' => "PBXFileReference",
        'lastKnownFileType' => "wrapper.framework",
        'name' => "FRAMEWORK.framework",
        'path' => "FRAMEWORK.framework",
        'sourceTree' => "<group>" }
        
      default_properties.merge(properties)
    end
    
    #
    # Generate the properties for a system framework.
    # 
    # @example CoreGraphics.framework
    # 
    #     FileReference.system_framework "CoreGraphics.framework"
    #     FileReference.system_framework "Foundation"
    # 
    # @param [String] name of the system framework which can be specified with or
    #   without the ".framework" suffix / extension.
    # @param [Hash] properties the parameters to override for the system framework
    # @return [Hash] system framework properties
    # 
    def self.system_framework(name,properties = {})
      name = name.gsub(File.extname(name),"")
      
      default_properties = { 'isa' => 'PBXFileReference',
        'lastKnownFileType' => 'wrapper.framework', 
        'name' => "#{name}.framework",
        'path' => "System/Library/Frameworks/#{name}.framework",
        "sourceTree" => "SDKROOT" }
        
      default_properties.merge(properties)
    end
    
    #
    # Generate the properties for a system library
    # 
    # @example libz.dylib
    # 
    #     FileReference.system_library "libz.dylib"
    # 
    # @param [String] name of the system library, which can be found by default
    #   in the /usr/lib folder.
    # @param [Types] properties the parameters to override for the system library
    # @return [Hash] system library properties
    # 
    def self.system_library(name,properties = {})
      default_properties = { 'isa' => 'PBXFileReference',
        'lastKnownFileType' => 'compiled.mach-o.dylib', 
        'name' => name,
        'path' => "usr/lib/#{name}",
        "sourceTree" => "SDKROOT" }
        
      default_properties.merge(properties)
    end
    
    #
    # @example app product properties
    # 
    #     E21D8AAA14E0F817002E56AA /* newtarget.app */ = {
    #       isa = PBXFileReference; 
    #       explicitFileType = wrapper.application; 
    #       includeInIndex = 0; 
    #       path = newtarget.app; 
    #       sourceTree = BUILT_PRODUCTS_DIR; };
    # 
    # @param [String] name name of the app product
    # @return [Hash] app product properties
    # 
    def self.app_product(name)
      { 'isa' => 'PBXFileReference',
        'explicitFileType' => 'wrapper.application',
        'includeInIndex' => 0,
        'path' => "#{name}.app",
        'sourceTree' => "BUILT_PRODUCTS_DIR" }
    end
    
    #
    # Remove the given file from the project and the supergroup of the file.
    # 
    def remove!
      # @todo the removal here does not consider if the files have
      #   been specified within a build phase.
      yield self if block_given?
      supergroup.children.delete identifier if supergroup
      @registry.remove_object identifier
    end
    
  end
  
end
