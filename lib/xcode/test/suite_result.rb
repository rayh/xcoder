module Xcode
  module Test
    class SuiteResult
      attr_accessor :tests, :name, :start_time, :end_time
  
      def initialize(name, start_time)
        @name = name
        @start_time = start_time
        @tests = []
      end

      def finish(time)
        raise "Time is nil" if time.nil?
        @end_time = time
      end

      def total_error_tests
        @tests.select {|t| t.error? }.count
      end

      def total_passed_tests
        @tests.select {|t| t.passed? }.count
      end

      def total_failed_tests
        @tests.select {|t| t.failed? }.count
      end
  
    end
  end
end