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
  
  end
  
end