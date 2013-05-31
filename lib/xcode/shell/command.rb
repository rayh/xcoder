require 'set'
require 'tmpdir'
require 'tempfile'
require 'pty'

module Xcode
  module Shell
    
    class ExecutionError < StandardError; 
      attr_accessor :output
      def initialize(message, output=nil)
        super message
        @output = output
      end
    end

    class Command
      include Xcode::TerminalOutput
      attr_accessor :env, :cmd, :args, :show_output, :output_dir, :log_to_file, :output

      def initialize(cmd, environment={})
        @cmd = cmd.to_s
        @args = []
        @env = environment
        @show_output = true
        @pipe = nil
        @output = []
        @output_dir = Dir.tmpdir
        @log_to_file = false
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
          output_file_name = File.join(@output_dir, "xcoder-#{@cmd}-#{Time.now.strftime('%Y%m%d-%H%M%S')}")
          
          File.open(output_file_name, "w") do |file|          
            PTY.spawn(to_s) do |r, w, child_pid|
              r.sync
              r.each_line do |line|
                file << line
                
                print_input line.gsub(/\n$/,''), :debug if @show_output 

                if @pipe.nil?
                  # DEPRECATED
                  yield(line) if block_given?
                else
                  @pipe << line
                end
                
                @output << line
              end 
              Process.wait(child_pid)
            end
          end
          
          raise ExecutionError.new("Error (#{$?.exitstatus}) executing '#{to_s}'", @output) if $?.exitstatus>0        

          if @log_to_file
            print_system "Captured output to #{output_file_name}", :notice                      
          else
            File.delete(output_file_name)
          end
          
          @output
        rescue Xcode::Shell::ExecutionError => e          
          print_system "Captured output to #{output_file_name}", :notice          
          print_system "Cropped #{e.output.count - 10} lines", :notice if @output.count>10
          @output.last(10).each do |line|
            print_output line.strip, :error
          end
          raise e      
        ensure
          @pipe.close unless @pipe.nil?
        end
      end
      
    end
  end
end