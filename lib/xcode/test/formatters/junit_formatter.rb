require 'builder'
require 'socket'

module Xcode
  module Test
    module Formatters
      class JunitFormatter
        def initialize(dir)
          @dir = dir
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
          
        end # write
        
      end # JUnitFormatter
      
    end # Formatters
  end # Test
end # Xcode