require 'xcode/test/report/suite_result'
require 'xcode/test/report/test_result'

module Xcode
  module Test    
    
    # The report is the abstract representation of a collection of suites of tests.  Formatters can be attached to write output
    # in real time
    class Report
      attr_reader :suites
      attr_accessor :failed, :start_time, :end_time, :exit_code, :unexpected
  
      def initialize
        @debug = false
        @exit_code = 0
        @suites = []
        @formatters = []
        @failed = false
        @start_time = nil
        @end_time = nil
        @unexpected = false
      
        yield self if block_given?
      end
      
      def unexpected?
        @unexpected
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
  
    end
    
    # The report builder is a state machine that takes some of the work out of writing a parser.  It "knows" which suites or 
    # testcase is currently active.
    class ReportBuilder
      attr_accessor :formatters
      
      class InvalidStateException < StandardError; end
      
      def initialize(report=Report.new)
        @report = report
        @formatters = []
        
        if block_given?
          yield self
        else
          add_formatter :junit, 'test-reports'
          add_formatter :stdout
        end
      end
      
      def add_formatter(format, *args)
        require "xcode/test/formatters/#{format.to_s}_formatter"
        formatter = Xcode::Test::Formatters.const_get("#{format.to_s.capitalize}Formatter").new(*args)
        @formatters << formatter
      end
      
      def current_suite
        @report.suites.last
      end
    
      def current_test
        @report.suites.last.tests.last unless current_suite.nil?
      end
      
      def abort
        @report.unexpected=true
      end
      
      def begin_all
        @report.start_time = Time.now
        notify_formatters(:before, @report)
      end
    
      def begin_suite(name, time=Time.now)
        @report.suites << Xcode::Test::Report::SuiteResult.new(name, time) 
        notify_formatters(:before_suite, current_suite)
      end

      def end_all
        return if @report.finished?
      
        # if there is a current, unfinished test - fail it
        unless current_test.nil? or current_test.passed?
          fail_test_case(0) 
          @report.failed = true
        end
      
        # if there is a current suite which isnt finished - finish it
        unless current_suite.nil? or current_suite.finished? 
          @report.failed = true # It may not have failed, but we want to indicate an unexpected end
          current_suite.finish
          notify_formatters(:after_suite, current_suite)
        end
      
        # finish all tests
        @report.end_time = Time.now
        notify_formatters(:after, @report)
      end
      
      def end_suite(time=Time.now)
        assert_active_suite
        @report.suites.last.finish(time)
        notify_formatters(:after_suite, current_suite)
      end

      def begin_test_case(name)
        assert_active_suite
        test = Xcode::Test::Report::TestResult.new(name, current_suite)
        @report.suites.last.tests << test
        notify_formatters(:before_test, test)
      end
   
      def pass_test_case(duration=0)
        assert_active_test
        @report.suites.last.tests.last.passed(duration)
        notify_formatters(:after_test, current_test)
      end
        
      def append_error_to_current_test(message, location)
        assert_active_test
        current_test.add_error(message, location)
        @report.failed = true
      end
      
      def fail_test_case(duration=0)
        assert_active_test
        current_test.failed(duration)
        notify_formatters(:after_test, current_test)
        @report.failed = true
      end
        
      def append_line_to_current_test(line)
        assert_active_test
        current_test << line
      end
    
      private 
      
      def assert_active_suite
        raise InvalidStateException.new("There is no active suite") if current_suite.nil? or !current_suite.end_time.nil?
      end
      
      def assert_active_test    
        assert_active_suite    
        raise InvalidStateException.new("There is no active test case") if current_test.nil?
      end
    
      def notify_formatters(event, obj=nil)
        @formatters.each do |f|
          f.send event, obj if f.respond_to? event
        end
      end
      
    end # Report
  end # Test
end # Xcode