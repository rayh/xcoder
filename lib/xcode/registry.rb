module Xcode
  module Registry
    
    def root
      self['rootObject']
    end
    
    def objects
      self['objects']
    end
    
    def object(identifier)
      objects[identifier]
    end
    
  end
end