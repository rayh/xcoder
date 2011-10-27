module Xcode
  module Shell
    def self.execute(bits, show_output=true)
      out = []
      cmd = bits.is_a?(Array) ? bits.join(' ') : bits
      
      puts "EXECUTE: #{cmd}"
      IO.popen (cmd) do |f| 
        f.each do |line|
          puts line if show_output
          out << line
        end 
      end
      #Process.wait
      raise "Error (#{$?.exitstatus}) executing '#{cmd}'\n\n  #{out.join("  ")}" if $?.exitstatus>0
      #puts "RETURN: #{out.inspect}"
      out
    end
  end
end