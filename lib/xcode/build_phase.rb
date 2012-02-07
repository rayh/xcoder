module Xcode
  
  module BuildPhase
    
    def file file_identifier
      files.find {|f| f.identifier == file_identifier }
    end
    
    #
    # Add the specified file to the Build Phase.
    # 
    # First a BuildFile entry is created for the file and then the build file
    # entry is added to the particular build phase. A BuildFile identifier must
    # exist for each target.
    # 
    # @param [FileReference] file the FileReference Resource to add to the build 
    # phase.
    #
    def add_file(file)
      
      build_identifier = @registry.add_object 'isa' => "PBXBuildFile", 'fileRef' => file.identifier
      @properties['files'] << build_identifier 
      
    end
    
  end
  
end