require 'json'
require 'plist'

module Xcode
  
  module PLUTILProjectParser
    extend self
  
    #
    # Using the sytem tool plutil, the specified project file is parsed and 
    # converted to XML, and then converted into a ruby hash object.
    # 
    def parse(path)
      registry = Plist.parse_xml open_project_file(path)
      
      raise "Failed to correctly parse the project file #{path}" unless registry
      
      registry
    end

    #
    # Save the outputed string data to the specified project file path and then
    # formats that data to be prettier than the default output.
    # 
    def save(path,data)
     
      File.open(path,'w') do |file|
        file.puts data
      end

      if File.exists?(path)
        `pl -input #{path} -output #{path}`
      end

    end
    
    private
    
    #
    # @return [String] an XML version of the project file or the error message
    #   that the file could not be found.
    # 
    # @example Error Message
    # 
    #       Project.xcodeproj/project.pbproj file does not exist or is not 
    #       readable or is not a regular file.
    # 
    def open_project_file(path)
      `plutil -convert xml1 -o - "#{path}"`
    end
      
  end
  
end
