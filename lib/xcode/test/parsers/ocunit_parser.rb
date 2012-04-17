require 'xcode/test/report'
require 'time'

module Xcode
  module Test    
    module Parsers
      
      class OCUnitParser
        attr_accessor :report, :builder
        
        def initialize(report = Xcode::Test::Report.new)
          @report = report          
          yield self if block_given?
        end
    
        def flush
          @report.finish
        end
    
        def <<(piped_row)
          case piped_row.force_encoding("UTF-8")
    
            when /Test Suite '(\S+)'.*started at\s+(.*)/
              name = $1
              time = Time.parse($2)
              if name=~/\//
                @report.start
              else
                @report.add_suite name, time
              end
            
            when /Test Suite '(\S+)'.*finished at\s+(.*)./
              time = Time.parse($2)
              name = $1
              if name=~/\//
                @report.finish
              else
                @report.in_current_suite do |suite|
                  suite.finish(time)
                end
              end

            when /Test Case '-\[\S+\s+(\S+)\]' started./
              name = $1
              @report.in_current_suite do |suite|
                suite.add_test_case name
              end

            when /Test Case '-\[\S+\s+(\S+)\]' passed \((.*) seconds\)/
              duration = $2.to_f
              @report.in_current_test do |test|
                test.passed(duration)
              end

            when /(.*): error: -\[(\S+) (\S+)\] : (.*)/
              message = $4
              location = $1
              @report.in_current_test do |test|
                test.add_error(message, location)
              end
            
            when /Test Case '-\[\S+ (\S+)\]' failed \((\S+) seconds\)/
              duration = $2.to_f
              @report.in_current_test do |test|
                test.failed(duration)
              end
            
            # when /failed with exit code (\d+)/, 
            when /BUILD FAILED/
              @report.finish
            
            when /Segmentation fault/
              @report.abort
            
            when /Run test case (\w+)/
              # ignore
            when /Run test suite (\w+)/
              # ignore
            when /Executed (\d+) test, with (\d+) failures \((\d+) unexpected\) in (\S+) \((\S+)\) seconds/
              # ignore
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