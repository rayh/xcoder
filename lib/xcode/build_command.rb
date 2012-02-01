module Xcode
  class BuildCommand
    
    def initialize
      @commands = {}
    end
    
    def << (value)
      key, value = value.split(' ')
      @commands[key] = Array(value).join(' ')
    end
    
    def to_s
      to_a.join(" ")
    end
    
    def to_a
      @commands.map {|cmd_value| cmd_value.join(" ").strip }
    end
    
    def <=> (value)
      to_a <=> value
    end
    
  end
end