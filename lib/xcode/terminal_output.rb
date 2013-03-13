require 'colorize'

module Xcode
  module TerminalOutput
    def self.included(base)
      @@colour_supported = terminal_supports_colors?
    end

    def color_output?
      @@colour_supported
    end

    def print_task(task, message, level=:info, cr=true)
    	print "#{task.rjust(10)}: ", :green

    	case level
    	when :error
    		print "[ERROR] ", :red
    	when :warning
    		print "[WARNING] ", :yellow
    	when :info    		
    		# color = :blue
    	when :success
    		# color = :green
    	else 
    		# color = :default
    	end
    	print message

    	if block_given?
    		yield
    	end

    	print "\n" if cr
    end

    def puts(text, color = :default)
      color_params = color_output? ? color : {}
      super(text.colorize(color_params))
    end

    def print(text, color = :default)
      color_params = color_output? ? color : {}
      super(text.colorize(color_params))
    end

    def self.terminal_supports_colors?
      # No colors unless we are being run via a TTY
      return false unless $stdout.isatty

      # Check if the terminal supports colors
      colors = `tput colors 2> /dev/null`.chomp
      if $?.exitstatus == 0
        colors.to_i >= 8
      else
        false
      end
    end
  end
end
