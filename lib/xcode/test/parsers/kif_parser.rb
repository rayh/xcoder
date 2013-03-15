require 'xcode/test/report'
require 'time'

module Xcode
  module Test    
    module Parsers
      
      class KIFParser
        attr_accessor :report, :builder
        
        def initialize(report = Xcode::Test::Report.new)
          @report = report
          @awaiting_scenario_name = false
          yield self if block_given?
        end
    
        def flush
          @report.finish
        end
    
        def <<(piped_row)
          if @awaiting_scenario_name
            if match = piped_row.match(/\[\d+\:.+\]\s(.+)/)
              name = match[1].strip
              @report.add_suite name, Time.now            
              @awaiting_scenario_name = false
            end
            return
          end
          
          case piped_row.force_encoding("UTF-8")
            
            when /BEGIN KIF TEST RUN: (\d+) scenarios/
              @report.start
            
            when /BEGIN SCENARIO (\d+)\/(\d+) \(\d+ steps\)/
              @awaiting_scenario_name = true
              
            when /END OF SCENARIO \(duration (\d+\.\d+)s/
              @report.in_current_suite do |suite|
                suite.finish(Time.now)
              end
              
            when /(PASS|FAIL) \((\d+\.\d+s)\): (.+)/
              duration = $2.to_f
              name = $3.strip
              @report.in_current_suite do |suite|
                test = suite.add_test_case(name)
                
                if $1 == 'PASS'
                  test.passed(duration)
                else
                  test.failed(duration)
                end
              end
              
            when /KIF TEST RUN FINISHED: \d+ failures \(duration (\d+\.\d+)s\)/
              @report.finish

            when /(.*): error: -\[(\S+) (\S+)\] : (.*)/
              message = $4
              location = $1
              @report.in_current_test do |test|
                test.add_error(message, location)
              end
            
            # when /failed with exit code (\d+)/, 
            when /BUILD FAILED/
              @report.finish
            
            when /Segmentation fault/
              @report.abort
            
            when /the iPhoneSimulator platform does not currently support application-hosted tests/
              raise "Application tests are not currently supported by the iphone simulator.  If these are logic tests, try unsetting TEST_HOST in your project config"
            else
              @report.in_current_test do |test|
                test << piped_row
              end
          end # case
        
        end # <<
      
      end # OCUnitParser
    end # Parsers
  end # Test
end # Xcode