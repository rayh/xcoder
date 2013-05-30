require 'xcode/shell/command.rb'
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
    
    def self.execute(cmd, show_output=true, show_command=false)
      out = []
      cmd = cmd.to_s
      PTY.spawn(cmd) do |r, w, child_pid|
        r.sync
        r.each_line do |line|
          puts line if show_output
          yield(line) if block_given?
          out << line
        end 
        Process.wait(pid)
      end
      raise ExecutionError.new("Error (#{$?.exitstatus}) executing '#{cmd}'", out) if $?.exitstatus>0
      out
    end
  end
end
