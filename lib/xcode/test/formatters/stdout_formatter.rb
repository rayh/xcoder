module Xcode
  module Test
    module Formatters
      class StdoutFormatter
        include Xcode::TerminalOutput
        
        def initialize(options = {})
          @errors = []
          @test_count = 0
          options.each { |k,v| self.send("#{k}=", v) }
        end
                
        def before(report)
          print_task :test, "Begin tests", :info
        end
        
        def after(report)
          level = @errors.count>0 ? :error : :info
          if @errors.count>0
            print_task :test, "The following failures occured:", :warning 
            @errors.each do |e|
              print_task :test, "[#{e.suite.name} #{e.name}]", :error
              e.errors.each do |error|
                print_task :test, "  #{error[:message]}", :error
                print_task :test, "    at #{error[:location]}", :error
                if error[:data].count>0
                  print_task :test, "\n   Test Output:", :error
                  print_task :test, "   > #{error[:data].join("   > ")}\n\n", :error
                end
              end       
              
              # if there is left over data in the test report, show that
              if e.data.count>0
                print_task :test, "\n  There was this trailing output after the above failures", :error
                print_task :test, "   > #{e.data.join("   > ")}\n\n", :error
              end
            end
          end
          
          print_task :test, "End tests (#{report.failed? ? 'FAILED' : 'PASSED'}).  Ran #{@test_count} tests in #{report.duration}s", report.failed? ? :error : :info
        end
        
        def before_suite(suite)
          print_task :test, "#{suite.name}: ", :info, false
        end
        
        def after_suite(suite)
          color = (suite.total_passed_tests == suite.tests.count) ? :info : :error
          #print_task :test, "#{suite.total_passed_tests}/#{suite.tests.count}", color
          puts " [#{suite.total_passed_tests}/#{suite.tests.count}]", color
        end
        
        def before_test(test)
          # puts "[#{test.suite.name} #{test.name}] << BEGIN"
        end
        
        def after_test(test)
          @test_count += 1
          if test.passed?
            print ".", :green
          elsif test.failed?
            print "F", :red
            @errors << test 
          end                    
        end
                
      end # StdoutFormatter
    end # Formatters
  end # Test
end # Xcode