module Xcode
  module Test
    class Report
      class SuiteResult
        attr_accessor :tests, :name, :start_time, :end_time
  
        def initialize(name, start_time)
          @name = name
          @start_time = start_time
          @tests = []
        end

        def finish(time=Time.now)
          raise "Time is nil" if time.nil?
          @end_time = time
        end
      
        def finished?
          !@end_time.nil?
        end
      
        def total_errors
          errors = 0
          @tests.each do |t| 
            errors = errors + t.errors.count if t.failed?
          end
          errors
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
end