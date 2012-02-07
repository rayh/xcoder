module Xcode
  
  #
  # Within the project file the PBXFileReference represents the object 
  # representation to the file on the file sytem. This is usually your source
  # files within your project.
  # 
  module FileReference
    
    # This is the group for which this file is contained within.
    attr_accessor :supergroup
    
    def self.with_properties_for_framework(name)
      { 'isa' => "PBXFileReference",
        'lastKnownFileType' => "wrapper.framework",
        'name' => "#{name}.framework",
        'path' => "System/Library/Frameworks/#{name}.framework",
        'sourceTree' => "SDKROOT" }
    end
    
    def self.with_properties_for_path(path)
      { 'isa' => 'PBXFileReference', 
        'path' => path,
        'sourceTree' => '<group>' }
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
    
  end
  
end