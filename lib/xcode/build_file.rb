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
    def self.buildfile(file_identifier,settings)
      properties = { 'isa' => "PBXBuildFile", 'fileRef' => file_identifier }
      properties.merge!('settings' => settings) unless settings.empty?
      properties
    end
    
  end
end