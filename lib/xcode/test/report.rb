require 'xcode/test/report/suite_result'
require 'xcode/test/report/test_result'

module Xcode
  module Test    
    
    module Formatters
    end
    
        
    # The report is the abstract representation of a collection of suites of tests.  Formatters can be attached to write output
    # in real time
    class Report
      attr_reader :suites, :observers
      attr_accessor :start_time, :end_time, :exit_code, :unexpected
      
      
      class InvalidStateException < StandardError; end
  
      def initialize
        @debug = false
        @exit_code = 0
        @suites = []
        @formatters = []
        @start_time = nil
        @end_time = nil
        @unexpected = false
        @observers = []
      
        yield self if block_given?
      end
      
      def add_formatter(format, *args)
        require "xcode/test/formatters/#{format.to_s}_formatter"
        formatter = Xcode::Test::Formatters.const_get("#{format.to_s.capitalize}Formatter").new(*args)
        @observers << formatter
      end
      
      def unexpected?
        @unexpected
      end
      
      def succeed?
        !self.failed?
      end
      
      def failed?
        return true if unexpected?
        
        @suites.each do |suite|
          suite.tests.each do |test|
            return true if test.failed?
          end
        end

        false
      end
      
      def start
        @start_time = Time.now
        notify_observers :before, self
      end
      
      def add_suite(name, time=Time.now)
        suite = Xcode::Test::Report::SuiteResult.new(self, name, time)
        @suites << suite
      end
      
      def finished?
        !@end_time.nil?
      end
      
      def duration
        return 0 if @start_time.nil?
        return Time.now - @start_time if @end_time.nil?
        @end_time - @start_time
      end
      
      def in_current_suite
        # raise InvalidStateException.new("There is no active suite")
        return if @suites.size==0 or !@suites.last.end_time.nil?
        yield @suites.last
      end
    
      def in_current_test
        in_current_suite do |suite|
          # raise InvalidStateException.new("There is no active test case")
          return if suite.tests.size==0
          yield suite.tests.last
        end
      end
       
      def finish
        return if finished?
      
        # if there is a current suite which isnt finished - finish it
        in_current_suite do |suite|
          unless suite.finished? 
            @unexpected = true
            suite.finish
          end
        end
        
        @end_time = Time.now
        notify_observers :after, self
      end
      
      def abort
        @report.unexpected=true
        finish
      end
    
      def notify_observers(event, obj=nil)
        @observers.each do |f|
          f.send event, obj if f.respond_to? event
        end
      end
      
    end # Report
  end # Test
end # Xcode