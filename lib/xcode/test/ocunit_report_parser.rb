require 'time'
require 'fileutils'
require 'xcode/test/suite_result'
require 'xcode/test/test_result'

module Xcode
  module Test
    
    module Formatters
    end
  
    class OCUnitReportParser

      attr_reader :exit_code, :reports
      attr_accessor :debug, :formatters
  
      def initialize
        @debug = false
        @exit_code = 0
        @reports = []
        @formatters = []
        
        add_formatter :junit, 'test-reports'
        add_formatter :stdout
      end
      
      def add_formatter(format, *args)
        require "xcode/test/formatters/#{format.to_s}_formatter"
        formatter = Formatters.const_get("#{format.to_s.capitalize}Formatter").new(*args)
        @formatters << formatter
      end
      
      def notify_formatters(event, obj=nil)
        @formatters.each do |f|
          f.send event, obj if f.respond_to? event
        end
      end
    
      def <<(piped_row)
        puts piped_row if @debug
        
        case piped_row
    
          when /Test Suite '(\S+)'.*started at\s+(.*)/
            name = $1
            time = Time.parse($2)
            if name=~/\//
              # all tests begin
              notify_formatters(:before, self)
            else
              @reports << SuiteResult.new(name, time) 
              notify_formatters(:before_suite, @reports.last)
            end
            
          when /Test Suite '(\S+)'.*finished at\s+(.*)./
            time = Time.parse($2)
            name = $1
            if name=~/\//
              # all tests ended
              notify_formatters(:after, self)
            else
              @reports.last.finish(time)
              notify_formatters(:after_suite, @reports.last)
            end

          when /Test Case '-\[\S+\s+(\S+)\]' started./
            test = TestResult.new($1, @reports.last)
            @reports.last.tests << test
            notify_formatters(:before_test, test)

          when /Test Case '-\[\S+\s+(\S+)\]' passed \((.*) seconds\)/
            @reports.last.tests.last.passed($2.to_f)
            notify_formatters(:after_test, @reports.last.tests.last)

          when /(.*): error: -\[(\S+) (\S+)\] : (.*)/
            @reports.last.tests.last.add_error($4,$1)
            @exit_code = 1 # should terminate
            # notify_formatters(:after_test, @reports.last.tests.last)
            
          when /Test Case '-\[\S+ (\S+)\]' failed \((\S+) seconds\)/
            @reports.last.tests.last.failed($2.to_f)
            @exit_code = 1  # should terminate
            notify_formatters(:after_test, @reports.last.tests.last)

          when /failed with exit code (\d+)/
            @exit_code = $1.to_i
      
          when /BUILD FAILED/
            @exit_code = -1;
            
          when /Run test suite (\w+)/
            # ignore
          when /Executed (\d+) test, with (\d+) failures \((\d+) unexpected\) in (\S+) \((\S+)\) seconds/
            # ignore
          else
            @reports.last.tests.last.data << piped_row unless @reports.last.nil? or @reports.last.tests.last.nil?
        end # case
        
      end # <<
      
    end # OCUnitReportParser
  end # Test
end # Xcode