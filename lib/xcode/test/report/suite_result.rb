module Xcode
  module Test
    class Report
      class SuiteResult
        attr_accessor :tests, :name, :start_time, :end_time, :report
  
        def initialize(report, name, start_time)
          @report = report
          @name = name
          @start_time = start_time
          @tests = []
          
          @report.notify_observers :before_suite, self
        end

        def finish(time=Time.now)
          raise "Time is nil" if time.nil?
    
          # Fail any lingering test
          finish_current_test
      
          @end_time = time
          @report.notify_observers :after_suite, self
        end
        
        def add_test_case(name)
          finish_current_test
          
          test = Xcode::Test::Report::TestResult.new self, name
          @tests << test
          yield(test) if block_given?
          test
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
        
        private
        
        def finish_current_test
          # Fail any lingering test
          unless @tests.size==0 or @tests.last.passed?
            @tests.last.failed(0) 
          end
        end
  
      end
    end
  end
end