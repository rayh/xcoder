module Xcode
  module Test
    class TestResult
      attr_reader :name, :time, :error_message, :error_location
    
      def initialize(name)
        @name = name
      end
    
      def passed?
        @passed
      end
    
      def failed?
        error? or !@passed
      end
      
      def error?
        !@error_message.nil?
      end
    
      def passed(time)
        @passed = true
        @time = time
      end
    
      def failed(time)
        @passed = false
        @time = time
      end
    
      def error(error_message,error_location)
        @error_message = error_message
        @error_location = error_location
      end
    end
  end
end