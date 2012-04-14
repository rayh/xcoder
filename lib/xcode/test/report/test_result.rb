module Xcode
  module Test
    class Report
      class TestResult
        attr_reader :name, :time, :errors, :suite, :data
    
        def initialize(suite, name)
          @name = name
          @data = []
          @suite = suite
          @errors = []  
          
          @suite.report.notify_observers :before_test, self
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
          @suite.report.notify_observers :after_test, self
        end
    
        def failed(time)
          @passed = false
          @time = time
          @suite.report.notify_observers :after_test, self
        end
      
        def << (line)
          # puts "[#{@suite.name} #{@name}] << #{line}"
          return if @data.count==0 and line.strip.empty?
          @data << line
        end
    
        def add_error(error_message,error_location)
          @errors << {:message => error_message, :location => error_location, :data => @data}
          @data = []
        end
      end
    end
  end
end