require 'xcode/test/report'
require 'time'

module Xcode
  module Builder    
    class XcodebuildParser  
      include Xcode::TerminalOutput
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
        # 'SymLink'
      ]

      def initialize
        @last_good_index = 0
        @last_step_name = nil
        @last_step_params = []
        @suppress_warnings = false
      end

      def close
      end

      def << piped_row
        piped_row = piped_row.force_encoding("UTF-8").gsub(/\n$/,'')

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
          elsif piped_row=~/^warning:/i
            log_xcode "#{piped_row.gsub(/^warning:\s/i,'')}", :warning
          elsif piped_row=~/^\[BEROR\](.*)/
            log_xcode "#{$1}", :error            
          elsif piped_row=~/^ld: warning:/i
            log_xcode "#{piped_row.gsub(/^ld: warning:\s/i,'')}", :warning       
          elsif piped_row=~/Unable to validate your application/
            log_xcode piped_row, :warning
            # print "\n warning: ", :yellow
            # print " #{piped_row}"
          elsif piped_row=~/bin\/libtool\:\s(.*)/
            log_xcode $1, :warning, :libtool

          # Pick up success
          elsif piped_row=~/\*\*\s.*SUCCEEDED\s\*\*/
            # yay, all good
            print "\n"

          elsif piped_row=~/^cp\s\-R/
            # Ignore 

          elsif piped_row=~/\sdeclared\shere$/
            # Ignore 

          # Pick up warnings/notes/errors
          elsif piped_row=~/^(.*:\d+:\d+): (\w+): (.*)$/
            # This is a warning/note/error
            type = $2.downcase
            level = :info
            if type=="warning"
              level = :warning
            elsif type=="error"
              level = :error
            end
            
            if (level==:warning or level==:note) and @suppress_warnings
              # ignore
            else
              log_xcode $3, level
              log_xcode "  at #{$1}", level
              # print "\n#{level.rjust(8)}: ", color
              # print $3
              # print "\n          at #{$1}"
            end

          # If there were warnings, this will be output
          elsif piped_row=~/\d+\swarning(s?)\sgenerated\./
            # TODO: is this safe to ignore?


          # This might be a build step 
          else
            step = piped_row.scan(/^(\S+)/).first.first
            if KNOWN_STEPS.include? step
              unless @last_step_name==step
                # print "\n" unless @last_step_name.nil?
                @last_step_name = step
                @last_step_params = []
                # print "#{"run".rjust(8)}: ", :green
                # print "#{step} "
              end
              unless @need_cr
                log_xcode step+" ", :info, false
              end
              print '.', :green
            else
              # Echo unknown output
              unless @suppress_warnings
                log_xcode piped_row, :info
                # print "\n        > ", :blue
                # print "#{piped_row}"
              end
            end
          end
        end
      rescue => e
        puts "Failed to parse '#{piped_row}' because #{e}", :red
      end # <<

      def log_xcode message, level, cr=true, task = :xcode
        print "\n" if @need_cr
        print_task task, message, level, cr
        @need_cr = !cr
      end
      
    end # XcodebuildParser
  end # Builder
end # Xcode
