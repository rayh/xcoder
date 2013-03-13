require 'xcode/test/report'
require 'time'
require 'xcode/terminal_colour'

module Xcode
  module Builder    
    class XcodebuildParser  
      include Xcode::TerminalColour
      attr_accessor :suppress_warnings

      KNOWN_STEPS = [
        'Clean.Remove',
        'Build',
        'Check',
        'ProcessInfoPlistFile',
        'CpResource',
        'ProcessPCH', 
        'CompileC', 
        'Ld', 
        'CreateUniversalBinary',
        'GenerateDSYMFile',
        'CopyPNGFile',
        'CompileXIB',
        'CopyStringsFile',
        'ProcessProductPackaging',
        'Touch',
        'CodeSign',
        'Libtool',
        'PhaseScriptExecution',
        'Validate'
      ]

      def initialize filename
        @file = File.open(filename, 'w')
        @last_good_index = 0
        @last_step_name = nil
        @last_step_params = []
        @suppress_warnings = true
      end

      def flush
        @file.close
      end

      def <<(piped_row)
        piped_row = piped_row.force_encoding("UTF-8").gsub(/\n$/,'')

        # Write it to the log
        @file.write piped_row + "\n"

        if piped_row=~/^\s+/
          @last_step_params << piped_row
        else
          if piped_row=~/\=\=\=\s/
            # This is just an info
          elsif piped_row=~/Build settings from command line/
            # Ignore
          elsif piped_row=~/Check dependencies/
            # Ignore
          elsif piped_row==''
            # Empty line, ignore
          elsif piped_row=~/[A-Z]+\s\=\s/
            # some build env info
          elsif piped_row=~/^warning:/
            print "\n warning: ", :yellow
            print "#{piped_row.gsub(/^warning:\s/,'')}"            
          elsif piped_row=~/Unable to validate your application/
            print "\n warning: ", :yellow
            print " #{piped_row}"

          # Pick up success
          elsif piped_row=~/\*\*\s.*SUCCEEDED\s\*\*/
            # yay, all good
            print "\n"

          # Pick up warnings/notes/errors
          elsif piped_row=~/^(.*:\d+:\d+): (\w+): (.*)$/
            # This is a warning/note/error
            level = $2.downcase
            color = :blue
            if level=="warning"
              color = :yellow
            elsif level=="error"
              color = :red
            end
            
            if (level=="warning" or level=="note") and @suppress_warnings
              # ignore
            else
              print "\n#{level.rjust(8)}: ", color
              print $3
              print "\n          at #{$1}"
            end

          # If there were warnings, this will be output
          elsif piped_row=~/\d+\swarning(s?)\sgenerated\./
            # TODO: is this safe to ignore?


          # This might be a build step 
          else
            step = piped_row.scan(/^(\S+)/).first.first
            if KNOWN_STEPS.include? step
              unless @last_step_name==step
                print "\n" unless @last_step_name.nil?
                @last_step_name = step
                @last_step_params = []
                print "#{"run".rjust(8)}: ", :green
                print "#{step} "
              end
              print '.', :green
            else
              # Echo unknown output
              print "\n        > ", :blue
              print "#{piped_row}"
            end
          end
        end
      rescue 
        puts "Failed to parse '#{piped_row}'", :red
      end # <<
      
    end # XcodebuildParser
  end # Builder
end # Xcode