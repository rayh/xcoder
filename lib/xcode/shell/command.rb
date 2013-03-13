require 'set'

module Xcode
  module Shell
    class Command
      include Xcode::TerminalOutput
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
      
      #
      # Execute the given command
      #
      def execute(show_output=true, &block) #:yield: output
        print_output self.to_s, :debug
        # print_task 'shell', self.to_s, :debug if show_output
        Xcode::Shell.execute(self, false) do |line|
          print_input line.gsub(/\n$/,''), :debug if show_output
          yield(line) if block_given?
        end
      end
      
    end
  end
end