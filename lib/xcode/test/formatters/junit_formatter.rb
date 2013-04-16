require 'builder'
require 'socket'

module Xcode
  module Test
    module Formatters
      class JunitFormatter
        def initialize(dir)
          @dir = File.expand_path(dir).to_s
          FileUtils.mkdir_p(@dir)
        end
        
        def after_suite(suite)
          write(suite)
        end

        def write(report)
          if report.end_time.nil?
            raise "Report #{report} #{report.name} has a nil end time!?"
          end
          xml = ::Builder::XmlMarkup.new( :indent => 2 )
          xml.instruct! :xml, :encoding => "UTF-8"
          xml.testsuite(:errors     => report.total_errors,
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
                ) do |testcase|
  
                t.errors.each do |error|
                  testcase.failure error[:location], :message => error[:message], :type => 'Failure'
                end
              end
            end
          end
          
          File.open(File.join(@dir, sanitize_filename("TEST-#{report.name}.xml")), 'w') do |current_file|
            current_file.write xml.target!
          end
          
        end # write
        
        private
        def sanitize_filename(filename)
           filename.gsub(/[^0-9A-Za-z.\-]/, '_')
        end
        
      end # JUnitFormatter
      
    end # Formatters
  end # Test
end # Xcode