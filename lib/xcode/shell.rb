require 'xcode/shell/command.rb'

module Xcode
  module Shell
    
    class ExecutionError < StandardError; end
    
    def self.execute(cmd, show_output=true)
      out = []
      cmd = cmd.to_s
      
      puts "EXECUTE: #{cmd}"
      IO.popen (cmd) do |f| 
        f.each do |line|
          puts line if show_output
          yield(line) if block_given?
          out << line
        end 
      end
      raise ExecutionError.new("Error (#{$?.exitstatus}) executing '#{cmd}'\n\n  #{out.join("  ")}") if $?.exitstatus>0
      out
    end
  end
end