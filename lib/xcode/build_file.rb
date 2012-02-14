module Xcode
  
  #
  # PBXBuildFile are entries within the project that create a link between the
  # file and the PBXFileReference. One is created for each file added to a build
  # target.
  # 
  module BuildFile
    
    #
    # Create the properties hash for a build file with the given file reference
    # identifier.
    # 
    # @param [String] file_identifier the unique identifier for the file
    # @return [Hash] the properties hash for a default BuildFile.
    # 
    def self.buildfile file_identifier
      { 'isa' => "PBXBuildFile", 'fileRef' => file_identifier }
    end

    #
    # Create the properties hash for a build file with the given file reference
    # identifier. This build file will not be compiled under ARC.
    # 
    # @example build file without ARC 
    # 
    #     {isa = PBXBuildFile; fileRef = 98A45A5E14BDF4580079B105 /* Reachability.m */; settings = {COMPILER_FLAGS = "-fno-objc-arc"; }; };
    # 
    # @param [String] file_identifier the unique identifier for the file
    # @return [Hash] the properties hash for a BuildFile that will not be
    #   compiled under ARC.
    #
    def self.buildfile_without_arc file_identifier
      { 'isa' => "PBXBuildFile", 
        'fileRef' => file_identifier, 
        'settings' => { 'COMPILER_FLAGS' => "-fno-objc-arc" } }
    end
    
  end
end