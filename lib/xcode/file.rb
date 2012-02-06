module Xcode
  
  #
  # Within the project file the PBXFileReference represents the object 
  # representation to the file on the file sytem. This is usually your source
  # files within your project.
  # 
  module PBXFileReference
    
    # This is the group for which this file is contained within.
    attr_accessor :supergroup
    
  end
  
end