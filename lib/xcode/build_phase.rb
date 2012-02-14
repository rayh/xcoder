module Xcode
  
  module BuildPhase
    
    # 
    # @return [BuildPhase] the framework specific build phase of the target.
    # 
    # @example
    # 
    #     7165D44D146B4EA100DE2F0E /* Frameworks */ = {
    #       isa = PBXFrameworksBuildPhase;                                        
    #       buildActionMask = 2147483647;                                         
    #       files = (                                                             
    #         7165D455146B4EA100DE2F0E /* UIKit.framework in Frameworks */,       
    #         7165D457146B4EA100DE2F0E /* Foundation.framework in Frameworks */,  
    #         7165D459146B4EA100DE2F0E /* CoreGraphics.framework in Frameworks */,
    #       );                                                                    
    #       runOnlyForDeploymentPostprocessing = 0;                               
    #     };                                                                      
    # 
    def self.framework
      { 'isa' => 'PBXFrameworksBuildPhase',
        'buildActionMask' => '2147483647',
        'files' => [],
        'runOnlyForDeploymentPostprocessing' => '0' }
    end
    
    #
    # @return [BuildPhase] the sources specific build phase of the target.
    # 
    def self.sources
      { 'isa' => 'PBXSourcesBuildPhase',
        'buildActionMask' => '2147483647',
        'files' => [],
        'runOnlyForDeploymentPostprocessing' => '0' }
    end
    
    #
    # @return [BuildPhase] the resources specific build phase of the target.
    # 
    def self.resources
      { 'isa' => 'PBXResourcesBuildPhase',
        'buildActionMask' => '2147483647',
        'files' => [],
        'runOnlyForDeploymentPostprocessing' => '0' }
    end
    
    #
    # Return the BuildFile given the file name.
    #
    # @param [String] name of the FileReference that is being built.
    # @return [BuildFile] the BuildFile that links to the file specified with 
    #   the name.
    # 
    def file(name)
      files.find {|file| file.file_ref.name == name or file.file_ref.path == name  }
    end
    
    #
    # Return the files that are referenced by the build files. This traverses
    # the level of indirection to make it easier to get to the FileReference.
    # 
    # Another method, file, exists which will return the BuildFile references.
    # 
    # @return [Array<FileReference>] the files referenced by the build files.
    # 
    def build_files
      files.map {|file| file.file_ref }
    end
    
    #
    # Find the first file that has the name or path that matches the specified
    # parameter.
    # 
    # @note this is the FileReference, the file being built and not the instance
    #   of the BuildFile.
    # 
    # @see #file
    # 
    # @param [String] name the name or the path of the file.
    # @return [FileReference] the file referenced that matches the name or path;
    #   nil if no file is found.
    # 
    def build_file(name)
      build_files.find {|file| file.name == name or file.path == name }
    end
    
    #
    # Add the specified file to the Build Phase.
    # 
    # First a BuildFile entry is created for the file and then the build file
    # entry is added to the particular build phase. A BuildFile identifier must
    # exist for each target.
    # 
    # @example adding a source file to the sources build phase
    # 
    #     spec_file = project.group('Specs/Controller').create_file('FirstControllerSpec.m')
    #     project.target('Specs').sources_build_phase.add_build_file spec_file
    # 
    # @example adding a source file, that does not use ARC, to the sources build phase
    # 
    #     spec_file = project.group('Specs/Controller').create_file('FirstControllerSpec.m')
    #     project.target('Specs').sources_build_phase.add_build_file spec_file, { 'COMPILER_FLAGS' => "-fno-objc-arc" }
    # 
    # @param [FileReference] file the FileReference Resource to add to the build 
    # phase.
    # @param [Hash] settings additional build settings that are specifically applied
    #   to this individual file.
    #
    def add_build_file(file,settings = {})
      find_file_by = file.name || file.path
      unless build_file(find_file_by)
        new_build_file = @registry.add_object BuildFile.buildfile(file.identifier,settings)
        @properties['files'] << new_build_file.identifier
      end
    end
    
    #
    # Add the specified file to the Build Phase.
    #
    #  
    # 
    # @param [FileReference] file the FileReference Resource to add to the build 
    # phase.
    # @param [Hash] settings additional build settings that are specifically applied
    #   to this individual file.
    #
    def add_build_file_without_arc(file)
      add_build_file file, { 'COMPILER_FLAGS' => "-fno-objc-arc" }
    end
    
  end
  
end