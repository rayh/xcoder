module Xcode
  
  #
  # Within the project file the PBXFileReference represents the object 
  # representation to the file on the file sytem. This is usually your source
  # files within your project.
  # 
  module FileReference
    
    # This is the group for which this file is contained within.
    attr_accessor :supergroup
    
    def self.file(properties)
      default_properties = { 'isa' => 'PBXFileReference', 
        # @todo this is not correct if the file is a .mm
        'lastKnownFileType' => 'sourcecode.c.objc',
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
    # @param [String] name of the system framework
    # @param [Hash] properties the parameters to override for the system framework
    #
    def self.system_framework(name,properties = {})
      default_properties = { 'isa' => 'PBXFileReference',
        'lastKnownFileType' => 'wrapper.framework', 
        'name' => "#{name}.framework",
        'path' => "System/Library/Frameworks/#{name}.framework",
        "sourceTree" => "SDKROOT" }
        
      default_properties.merge(properties)
    end
    
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
    def self.app_product(name)
      { 'isa' => 'PBXFileReference',
        'explicitFileType' => 'wrapper.application',
        'includeInIndex' => 0,
        'path' => "#{name}.app",
        'sourceTree' => "BUILT_PRODUCTS_DIR" }
    end
    
    
    def remove!
      # @todo the removal here does not consider if the files have
      #   been specified within a build phase.
      supergroup.children.delete identifier if supergroup
      @registry.remove_object identifier
    end
    
  end
  
end