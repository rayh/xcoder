require 'colorize'

module Xcode
  module Test
    module Formatters
      class StdoutFormatter
        attr_writer :color_output
        
        def initialize(options = {})
          @errors = []
          @color_output = terminal_supports_colors?
          options.each { |k,v| self.send("#{k}=", v) }
        end
        
        def color_output?
          @color_output
        end
                
        def before(report)
          puts "Begin tests", :green
        end
        
        def after(report)
          puts "\n\nThe following failures occured:", :yellow if @errors.count>0
          @errors.each do |e|
            puts "[#{e.suite.name} #{e.name}]", :red
            e.errors.each do |error|
              puts "  #{error[:message]}"
              puts "    at #{error[:location]}"
              if error[:data].count>0
                puts "\n   Test Output:"
                puts "   > #{error[:data].join("   > ")}\n\n"
              end
            end       
            
            # if there is left over data in the test report, show that
            if e.data.count>0
              puts "\n  There was this trailing output after the above failures"
              puts "   > #{e.data.join("   > ")}\n\n"
            end
          end
          
          color = report.failed? ? :red : :green
          puts "\n\nEnd tests (#{report.failed? ? 'FAILED' : 'PASSED'}).  Took #{report.duration}s", color
        end
        
        def before_suite(suite)
          print "#{suite.name}: "
        end
        
        def after_suite(suite)
          color = (suite.total_passed_tests == suite.tests.count) ? :green : :red
          puts " [#{suite.total_passed_tests}/#{suite.tests.count}]", color
        end
        
        def before_test(test)
          # puts "[#{test.suite.name} #{test.name}] << BEGIN"
        end
        
        def after_test(test)
          if test.passed?
            print ".", :green
          elsif test.failed?
            print "F", :red
            @errors << test 
          end                    
        end
        
        private
        def puts(text, color = :default)
          color_params = color_output? ? color : {}
          super(text.colorize(color_params))
        end
        
        def print(text, color = :default)
          color_params = color_output? ? color : {}
          super(text.colorize(color_params))
        end
        
        def terminal_supports_colors?
          # No colors unless we are being run via a TTY
          return false unless $stdout.isatty
          
          # Check if the terminal supports colors
          colors = `tput colors 2> /dev/null`.chomp
          if $?.exitstatus != 0
            colors.to_i >= 8
          else
            false
          end
        end
                
      end # StdoutFormatter
    end # Formatters
  end # Test
end # Xcode