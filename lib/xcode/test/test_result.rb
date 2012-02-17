module Xcode
  module Test
    class TestResult
      attr_reader :name, :time, :errors, :suite, :data
    
      def initialize(name, suite)
        @name = name
        @data = []
        @suite = suite
        @errors = []
      end
    
      def passed?
        @passed
      end
    
      def failed?
        !@passed
      end
    
      def passed(time)
        @passed = true
        @time = time
      end
    
      def failed(time)
        @passed = false
        @time = time
      end
    
      def add_error(error_message,error_location)
        @errors << {:message => error_message, :location => error_location, :data => @data}
        @data = []
      end
    end
  end
end