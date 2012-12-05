require 'set'

module Xcode
  module Shell
    class Command
      attr_accessor :env, :cmd, :args

      def initialize(cmd, environment={})
        @cmd = cmd
        @args = []
        @env = environment
      end
    
      def <<(arg)
        @args << arg
      end
    
      def to_s
        "#{to_a.join(' ')}"
      end
      
      def to_a
        out = []
        out << @cmd
        out+=@args
        out+=(@env.map {|k,v| "#{k}=#{v}"})
        out
      end
      
      def ==(obj)
        return false unless obj.is_a? Xcode::Shell::Command
        # to_s==obj.to_s
        Set.new(obj.to_a) == Set.new(self.to_a)
      end
      
      def execute(show_output=true, &block) #:yield: output
        Xcode::Shell.execute(self, show_output, &block)
      end
      
    end
  end
end