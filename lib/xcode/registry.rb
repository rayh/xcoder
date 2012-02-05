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
    
    def add_object object_properties
      # define a new group within the object list
      # add it as a child
      
      range = ('A'..'F').to_a + (0..9).to_a
      
      new_identifier = 24.times.inject("") {|ident| "#{ident}#{range.sample}" }
      
      # TODO ensure identifier does not collide with other identifiers
      
      objects[new_identifier] = object_properties
      
      new_identifier
    end
    
  end
end