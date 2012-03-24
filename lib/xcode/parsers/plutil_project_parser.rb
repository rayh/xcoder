require 'json'
require 'plist'

module Xcode
  
  module PLUTILProjectParser
    extend self
  
    #
    # Using the sytem tool plutil, the specified project file is parsed and 
    # converted to XML, and then converted into a ruby hash object.
    # 
    def parse path
      xml = `plutil -convert xml1 -o - "#{path}"`
      Plist::parse_xml(xml)
    end

    #
    # Save the outputed string data to the specified project file path and then
    # formats that data to be prettier than the default output.
    # 
    def save path,data
     
      File.open(path,'w') do |file|
        file.puts data
      end

      #
      
      if File.exists?(path)
        `pl -input #{path} -output #{path}`
      end

   end
  
  end
  
end
