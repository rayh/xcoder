module Xcode
  
  module BuildPhase
    
    def file file_identifier
      files.find {|f| f.identifier == file_identifier }
    end
    
    def add_file file_identifier
      @properties['files'] << file_identifier
    end
    
  end
  
end