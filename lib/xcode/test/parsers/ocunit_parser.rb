require 'xcode/test/report'
require 'time'

module Xcode
  module Test    
    module Parsers
      
      class OCUnitParser
        attr_accessor :report, :builder
        
        def initialize
          @report   = Xcode::Test::Report.new
          @builder  = Xcode::Test::ReportBuilder.new @report
          
          yield self if block_given?
        end
    
        def flush
          @builder.end_all
        end
    
        def <<(piped_row)
          puts piped_row if @debug
        
          case piped_row
    
            when /Test Suite '(\S+)'.*started at\s+(.*)/
              name = $1
              time = Time.parse($2)
              if name=~/\//
                @builder.begin_all
              else
                @builder.begin_suite(name, time)
              end
            
            when /Test Suite '(\S+)'.*finished at\s+(.*)./
              time = Time.parse($2)
              name = $1
              if name=~/\//
                @builder.end_all
              else
                @builder.end_suite(time)
              end

            when /Test Case '-\[\S+\s+(\S+)\]' started./
              @builder.begin_test_case($1)

            when /Test Case '-\[\S+\s+(\S+)\]' passed \((.*) seconds\)/
              @builder.pass_test_case($2.to_f)

            when /(.*): error: -\[(\S+) (\S+)\] : (.*)/
              @builder.append_error_to_current_test($4,$1)
            
            when /Test Case '-\[\S+ (\S+)\]' failed \((\S+) seconds\)/
              @builder.fail_test_case($2.to_f)
            
            # when /failed with exit code (\d+)/, 
            when /BUILD FAILED/ 
              @builder.end_all
            
            when /Segmentation fault/
              @builder.abort
            
            when /Run test case (\w+)/
              # ignore
            when /Run test suite (\w+)/
              # ignore
            when /Executed (\d+) test, with (\d+) failures \((\d+) unexpected\) in (\S+) \((\S+)\) seconds/
              # ignore
            else
              @builder.append_line_to_current_test piped_row
          end # case
        
        end # <<
      
      end # OCUnitParser
    end # Parsers
  end # Test
end # Xcode