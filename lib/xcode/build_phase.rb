module Xcode
  
  module BuildPhase
    
    #
    # Return the files that are referenced by the build files. This traverses
    # the level of indirection to make it easier to get to the FileReference.
    # 
    # Another method, file, exists which will return the BuildFile references.
    # 
    # @return [Array<FileReference>] the files referenced by the build files.
    # 
    def build_files
      files.map {|file| file.fileRef }
    end
    
    #
    # Find the first file that has the name or path that matches the specified
    # parameter. 
    # 
    # @param [String] name the name or the path of the file.
    # @return [FileReference] the file referenced that matches the name or path;
    #   nil if no file is found.
    # 
    def build_file(name)
      build_files.find {|file| file.name == name || file.path == name }
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
    def add_build_file(file)
      build_identifier = @registry.add_object BuildFile.with_properties(file.identifier)
      @properties['files'] << build_identifier 
    end
    
  end
  
end