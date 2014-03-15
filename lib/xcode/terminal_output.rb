require 'colorize'

module Xcode
  module TerminalOutput
    @@colour_enabled = true
    @@log_level = :info

    LEVELS = [
      :error,
      :warning,
      :notice,
      :info,
      :debug
    ]

    def log_level
      @@log_level
    end

    def self.log_level=(level)
      raise "Unknown log level #{level}, should be one of #{LEVELS.join(', ')}" unless LEVELS.include? level
      @@log_level = level
    end

    def self.included(base)
      @@colour_supported = terminal_supports_colors?
    end

    def color_output= color_output
      @@colour_enabled = color_output
    end

    def color_output?
      @@colour_supported and @@colour_enabled
    end

    #
    # Print an IO input interaction
    #
    def print_input message, level=:debug
      return if LEVELS.index(level) > LEVELS.index(@@log_level)
      puts format_lhs("", "", "<") + message, :default
    end

    #
    # Print an IO output interaction
    def print_output message, level=:debug
      return if LEVELS.index(level) > LEVELS.index(@@log_level)
      puts format_lhs("", "", ">") + message, :default
    end
    
    def print_system message, level=:debug
      return if LEVELS.index(level) > LEVELS.index(@@log_level)
      puts format_lhs("", "", "!") + message, :green
    end
    
    def format_lhs(left, right, terminator=":")
      # "#{left.to_s.ljust(10)} #{right.rjust(6)}#{terminator} "
      "#{right.to_s.rjust(7)}#{terminator} "
    end

    def print_task(task, message, level=:info, cr=true)
      return if LEVELS.index(level) > LEVELS.index(@@log_level)

      level_str = ""
      case level
      when :error
        level_str = "ERROR"
        color = :red
      when :warning
        level_str = "WARN"
        color = :yellow
      when :notice
        level_str = "NOTICE"
        color = :green
      when :info
        level_str = ""
        color = :blue
      else
        color = :default
      end

      print format_lhs(task, level_str), color
      print message, (level==:warning or level==:error or level==:notice) ? color : :default

      if block_given?
        yield
      end

      print "\n" if cr
    end

    def puts(text, color = :default)
      if not(color_output?) || color == :default
        super(text)
      else
        super(text.colorize(color))
      end
    end

    def print(text, color = :default)
      if not(color_output?) || color == :default
        super(text)
      else
        super(text.colorize(color))
      end
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
