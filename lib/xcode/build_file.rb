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
    def self.with_properties file_identifier
      { 'isa' => "PBXBuildFile", 'fileRef' => file_identifier }
    end
    
  end
end