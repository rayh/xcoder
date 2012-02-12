require 'time'
require 'FileUtils'
require 'socket'
require 'builder'

module Xcode
  module Test
    module Formatters
      class JunitFormatter
        def initialize(dir)
          @dir = dir
        end
      
        def string_to_xml(s)
          s.gsub(/&/, '&amp;').gsub(/'/, '&quot;').gsub(/</, '&lt;')
        end

        def write(report)
          if report.end_time.nil?
            raise "Report #{report} #{report.name} has a nil end time!?"
          end
          xml = ::Builder::XmlMarkup.new( :indent => 2 )
          xml.instruct! :xml, :encoding => "UTF-8"
          xml.testsuite(:errors     => report.total_error_tests,
            :failures   => report.total_failed_tests,
            :hostname   => Socket.gethostname,
            :name       => report.name,
            :tests      => report.tests.count,
            :time       => (report.end_time - report.start_time),
            :timestamp  => report.end_time
            ) do |p|     
                     
            report.tests.each do |t|
              p.testcase(:classname  => report.name,
                :name       => t.name,
                :time       => t.time
                ) do |e|
  
                if t.error?
                  e.failure t.error_location, :message => t.error_message, :type => 'Failure'
                end
              end
            end
          end
            
          File.open("#{@dir}/TEST-#{report.name}.xml", 'w') do |current_file|
            current_file.write xml.target!
          end
          
        end
      end
    end
  
    class SuiteReport
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
  
    class CaseReport
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
  
    class ReportParser

      attr_reader :exit_code, :reports
  
      def initialize
        @exit_code = 0
        @reports = []
      end

      def write(dir, format=:junit)
        dir = File.expand_path(dir)
        FileUtils.mkdir_p(dir)
      
        formatter = Formatters.const_get("#{format.to_s.capitalize}Formatter").new(dir)
        @reports.each do |r|
          formatter.write(r)
        end
      end
    
      def <<(piped_row)
        case piped_row
    
          when /Test Suite '(\S+)'.*started at\s+(.*)/
            name = $1
            time = Time.parse($2)
            @reports << SuiteReport.new(name, time) unless name=~/\// # ignore if its a file path

          when /Test Suite '(\S+)'.*finished at\s+(.*)./
            @reports.last.finish(Time.parse($2))

          when /Test Case '-\[\S+\s+(\S+)\]' started./
            test = CaseReport.new($1)
            @reports.last.tests << test

          when /Test Case '-\[\S+\s+(\S+)\]' passed \((.*) seconds\)/
            @reports.last.tests.last.passed($2.to_f)

          when /(.*): error: -\[(\S+) (\S+)\] : (.*)/
            @reports.last.tests.last.error(error_message,error_location)
            @exit_code = 1 # should terminate
            
          when /Test Case '-\[\S+ (\S+)\]' failed \((\S+) seconds\)/
            @reports.last.tests.last.failed($2.to_f)
            @exit_code = 1  # should terminate

          when /failed with exit code (\d+)/
            @exit_code = $1.to_i
      
          when
            /BUILD FAILED/
            @exit_code = -1;
        end
      end
    end
  end
end