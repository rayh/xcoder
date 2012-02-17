module Xcode
  module Test
    module Formatters
      class StdoutFormatter
        
        def initialize
          @errors = []
        end
                
        def before(report)
          puts "Begin tests"
        end
        
        def after(report)
          puts "\n\nThe following failures occured:" if @errors.count>0
          @errors.each do |e|
            puts "[#{e.suite.name} #{e.name}]"
            e.errors.each do |error|
              puts "  #{error[:message]}"
              puts "    at #{error[:location]}"
              puts "\n   Test Output:"
              puts "   > #{error[:data].join("   > ")}\n\n"
            end            
          end
          
          puts "End tests (exit code #{report.exit_code})"
        end
        
        def before_suite(suite)
          print "#{suite.name}: "
        end
        
        def after_suite(suite)
          puts " [#{suite.total_passed_tests}/#{suite.tests.count}]"
        end
        
        def before_test(test)
        end
        
        def after_test(test)
          if test.passed?
            print "." 
          elsif test.failed?
            print "F"
            @errors << test 
          end 
        end
                
      end # StdoutFormatter
    end # Formatters
  end # Test
end # Xcode