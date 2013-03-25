require 'set'

module Xcode
  module Shell

    class Command
      include Xcode::TerminalOutput
      attr_accessor :env, :cmd, :args, :show_output

      def initialize(cmd, environment={})
        @cmd = cmd
        @args = []
        @env = environment
        @show_output = true
        @pipe = nil
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
      # Attach an output pipe.  
      #
      # This can be any object which responds to puts and close 
      def attach(pipe)
        @pipe = pipe
        @show_output = false
      end
      
      #
      # Execute the given command
      #
      def execute(&block) #:yield: output
        print_output self.to_s, :debug
        # print_task 'shell', self.to_s, :debug if show_output
        begin
          Xcode::Shell.execute(self, false) do |line|
            print_input line.gsub(/\n$/,''), :debug if @show_output 

            if @pipe.nil?
              # DEPRECATED
              yield(line) if block_given?
            else
              @pipe << line
            end
          end
        ensure
          @pipe.close unless @pipe.nil?
        end
      end
      
    end
  end
end