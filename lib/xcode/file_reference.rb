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
    
  end
  
end