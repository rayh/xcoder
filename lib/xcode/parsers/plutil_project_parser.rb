require 'json'

module Xcode
  
  module PLUTILProjectParser
    extend self
  
    #
    # Using the sytem tool plutil, the specified project file is parsed and 
    # converted to JSON, which is then converted to a hash object.
    # 
    def parse path
      JSON.parse(`plutil -convert json -o - "#{path}"`)
    end
  
  end
  
end