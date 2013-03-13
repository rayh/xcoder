require 'xcode/test/report'
require 'time'
require 'xcode/terminal_colour'

module Xcode
  module Builder    
    class XcodebuildParser  
      include Xcode::TerminalColour

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
        'Validate'
      ]

      def initialize filename
        @file = File.open(filename, 'w')
        @last_good_index = 0
        @last_step_name = nil
        @last_step_params = []
      end

      def flush
        @file.close
      end

      def <<(piped_row)
        piped_row = piped_row.force_encoding("UTF-8").gsub(/\n$/,'')

        # Write it to the log
        @file.write piped_row

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
            print "\n  WARNING: ", :red
            print "#{piped_row.gsub(/^warning:\s/,'')}"            
          elsif piped_row=~/Unable to validate your application/
            print "\n  WARNING: ", :red
            print " #{piped_row}"
          elsif piped_row=~/\*\*\s.*SUCCEEDED\s\*\*/
            # yay, all good
            print "\n"
          else
            step = piped_row.scan(/^(\S+)/).first.first
            if KNOWN_STEPS.include? step
              unless @last_step_name==step
                print "\n" unless @last_step_name.nil?
                @last_step_name = step
                @last_step_params = []
                print "  #{step}: "
              end
              print '.', :grey
            else
              print "\n  ERROR: #{piped_row}", :red
            end
          end
        end
      rescue 
        puts "Failed to parse '#{piped_row}'", :red
      end # <<
      
    end # XcodebuildParser
  end # Builder
end # Xcode