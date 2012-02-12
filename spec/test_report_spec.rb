require 'rspec'
require 'xcoder'

describe Xcode::Test::OCUnitReportParser do 
  
  def example_report
    t = Xcode::Test::OCUnitReportParser.new
    t << "Run test suite AnExampleTestSuite"
    t << "Test Suite 'AnExampleTestSuite' started at 2012-02-10 00:37:04 +0000"
    
    t << "Run test case anExampleTest1"
    t << "Test Case '-[AnExampleTestSuite anExampleTest1]' started."
    t << "Test Case '-[AnExampleTestSuite anExampleTest1]' passed (0.003 seconds)."

    t << "Run test case anExampleTest2"
    t << "Test Case '-[AnExampleTestSuite anExampleTest2]' started."
    t << "Test Case '-[AnExampleTestSuite anExampleTest2]' passed (0.003 seconds)."
    
    yield(t) if block_given?
    
    t << "Test Suite 'AnExampleTestSuite' finished at 2012-02-10 00:37:04 +0000."
    t << "Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds"
    
    t
  end
  
  def example_failing_report
    example_report do |t|
      t << "Test Case '-[AnExampleTestSuite aFailingTest]' started."
      t << "Test Case '-[AnExampleTestSuite aFailingTest]' failed (2 seconds)."
    end
  end
  
  it "should create a test case" do 
    t = example_report
    t.reports.count.should==1
    t.reports.first.name.should=="AnExampleTestSuite"
    t.reports.first.start_time.should==Time.parse("2012-02-10 00:37:04 +0000")
    t.reports.first.end_time.should==Time.parse("2012-02-10 00:37:04 +0000")
  end
  
  it "should set the exist status to 0" do
    t = example_report
    t.exit_code.should==0
  end
  
  it "should set the exit status to non 0" do 
    t = example_failing_report
    t.exit_code.should_not==0
  end
  
  it "should record a failure" do
    t = example_failing_report
    t.reports.first.total_failed_tests.should==1
  end
  
  it "should create a test case with some tests" do 
    t = example_report
    
    t.reports.count.should==1
    t.reports.first.tests.count.should==2
    t.reports.first.tests[0].name.should=='anExampleTest1'
    t.reports.first.tests[0].time.should==0.003
    t.reports.first.tests[0].passed?.should==true
    
    t.reports.first.tests[1].name.should=='anExampleTest2'
    t.reports.first.tests[1].time.should==0.003
    t.reports.first.tests[1].passed?.should==true
  end

  it "should write out reports in junit format" do 
    report_dir = "#{File.dirname(__FILE__)}/test-reports"
    FileUtils.rm_rf report_dir
    
    t = example_report
    t.write(report_dir, :junit)
    
    files = Dir["#{report_dir}/*.xml"]
    files.count.should==1
    files.first.should=~/TEST-AnExampleTestSuite.xml$/
    
    # FIXME: parse the report
  end
  
end