require 'time'
require 'fileutils'
require 'xcode/test/suite_result'
require 'xcode/test/test_result'

module Xcode
  module Test
    
    module Formatters
    end
  
    class OCUnitReportParser

      attr_reader :exit_code, :reports
  
      def initialize
        @exit_code = 0
        @reports = []
      end

      def write(dir, format=:junit)
        dir = File.expand_path(dir)
        FileUtils.mkdir_p(dir)
      
        require "xcode/test/formatters/#{format.to_s}_formatter"
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
            @reports << SuiteResult.new(name, time) unless name=~/\// # ignore if its a file path

          when /Test Suite '(\S+)'.*finished at\s+(.*)./
            @reports.last.finish(Time.parse($2))

          when /Test Case '-\[\S+\s+(\S+)\]' started./
            test = TestResult.new($1)
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