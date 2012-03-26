
module Xcode
  class EnumerationProperty
    
    attr_reader :enumeration
    
    def initialize(*args)
      @enumeration = args.flatten.compact
    end
    
    def open(value)
      warn "Configuration property contains a value '#{value}' not within the enumeration." unless enumeration.include?(value)
      value
    end
    
    def save(value)
      raise "Configuration property value specified '#{value}' not within the enumeration." unless enumeration.include?(value)
      value
    end
    
    def append(original,value)
      warn "Overriding configuration property '#{original}' with new value '#{value}'" unless original == value
      save(value)
    end
    
  end
end