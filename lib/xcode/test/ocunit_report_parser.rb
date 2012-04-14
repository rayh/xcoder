require 'time'
require 'fileutils'
require 'xcode/test/suite_result'
require 'xcode/test/test_result'

module Xcode
  module Test
    
    module Formatters
    end
  
    class OCUnitReportParser

      attr_reader :reports, :end_time, :start_timel
      attr_accessor :debug, :formatters
  
      def initialize
        @debug = false
        @exit_code = 0
        @reports = []
        @formatters = []
        @failed = false
        @start_time = nil
        @end_time = nil
        @unexpected = false
        
        add_formatter :junit, 'test-reports'
        add_formatter :stdout
      end
      
      def unexpected?
        @unexpected
      end

      def succeed?
        !self.failed?
      end

      def failed?
        @failed or @unexpected
      end
      
      def finished?
        !@end_time.nil?
      end
      
      def duration
        return 0 if @start_time.nil?
        return Time.now - @start_time if @end_time.nil?
        @end_time - @start_time
      end
      
      def add_formatter(format, *args)
        require "xcode/test/formatters/#{format.to_s}_formatter"
        formatter = Formatters.const_get("#{format.to_s.capitalize}Formatter").new(*args)
        @formatters << formatter
      end
      
      def flush
        return if finished?
        
        # if there is a current, unfinished test - fail it
        unless current_test.nil? or current_test.passed?
          fail_current_test(0) 
          @failed = true
        end
        
        # if there is a current suite which isnt finished - finish it
        unless current_suite.nil? or current_suite.finished? 
          @failed = true # It may not have failed, but we want to indicate an unexpected end
          current_suite.finish
          notify_formatters(:after_suite, current_suite)
        end
        
        # finish all tests
        @end_time = Time.now
        notify_formatters(:after, self)
      end
    
      def <<(piped_row)
        puts piped_row if @debug
        
        case piped_row.force_encoding("UTF-8")
    
          when /Test Suite '(\S+)'.*started at\s+(.*)/
            name = $1
            time = Time.parse($2)
            if name=~/\//
              # all tests begin
              @start_time = Time.now
              notify_formatters(:before, self)
            else
              @reports << SuiteResult.new(name, time) 
              notify_formatters(:before_suite, current_suite)
            end
            
          when /Test Suite '(\S+)'.*finished at\s+(.*)./
            time = Time.parse($2)
            name = $1
            if name=~/\//
              # all tests ended
              @end_time = Time.now
              notify_formatters(:after, self)
            else
              @reports.last.finish(time)
              notify_formatters(:after_suite, current_suite)
            end

          when /Test Case '-\[\S+\s+(\S+)\]' started./
            test = TestResult.new($1, current_suite)
            @reports.last.tests << test
            notify_formatters(:before_test, test)

          when /Test Case '-\[\S+\s+(\S+)\]' passed \((.*) seconds\)/
            @reports.last.tests.last.passed($2.to_f)
            notify_formatters(:after_test, current_test)

          when /(.*): error: -\[(\S+) (\S+)\] : (.*)/
            current_test.add_error($4,$1)
            @failed = true
            # notify_formatters(:after_test, @reports.last.tests.last)
            
          when /Test Case '-\[\S+ (\S+)\]' failed \((\S+) seconds\)/
            fail_current_test($2.to_f)
            @failed = true
            
          # when /failed with exit code (\d+)/, 
          when /BUILD FAILED/
            flush
            
          when /Segmentation fault/
            @unexpected=true
            
          when /Run test case (\w+)/
            # ignore
          when /Run test suite (\w+)/
            # ignore
          when /Executed (\d+) test, with (\d+) failures \((\d+) unexpected\) in (\S+) \((\S+)\) seconds/
            # ignore
          else
            append_line_to_current_test piped_row
        end # case
        
      end # <<
      
      private 
      
      def notify_formatters(event, obj=nil)
        @formatters.each do |f|
          f.send event, obj if f.respond_to? event
        end
      end
      
      def current_suite
        @reports.last
      end
      
      def current_test
        @reports.last.tests.last unless current_suite.nil?
      end
      
      def fail_current_test(duration=0)
        return if current_test.nil?
        
        current_test.failed(duration)
        notify_formatters(:after_test, current_test)
      end
      
      def append_line_to_current_test(line)
        return if current_suite.nil? or !current_suite.end_time.nil?
        return if current_test.nil?
        current_test << line
      end
      
      
    end # OCUnitReportParser
  end # Test
end # Xcode