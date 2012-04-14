require 'rspec'
require 'xcoder'

describe Xcode::Test::OCUnitReportParser do 
  
  def example_report
    t = Xcode::Test::OCUnitReportParser.new
    yield(t) if block_given?
    
    t << "Run test suite AnExampleTestSuite"
    t << "Test Suite 'AnExampleTestSuite' started at 2012-02-10 00:37:04 +0000"
    
    t << "Run test case anExampleTest1"
    t << "Test Case '-[AnExampleTestSuite anExampleTest1]' started."
    t << "Test Case '-[AnExampleTestSuite anExampleTest1]' passed (0.003 seconds)."

    t << "Run test case anExampleTest2"
    t << "Test Case '-[AnExampleTestSuite anExampleTest2]' started."
    t << "Test Case '-[AnExampleTestSuite anExampleTest2]' passed (0.003 seconds)."
    
    t << "Test Suite 'AnExampleTestSuite' finished at 2012-02-10 00:37:04 +0000."
    t << "Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds"
    
    t
  end
  
  def example_failing_report    
    t = Xcode::Test::OCUnitReportParser.new
    t << "Run test suite AnExampleTestSuite"
    t << "Test Suite 'AnExampleTestSuite' started at 2012-02-10 00:37:04 +0000"
    t << "Test Case '-[AnExampleTestSuite aFailingTest]' started."
    yield(t) if block_given?
    t << "Test Case '-[AnExampleTestSuite aFailingTest]' failed (2 seconds)."
    t << "Test Suite 'AnExampleTestSuite' finished at 2012-02-10 00:37:04 +0000."
    t << "Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds"
    t
  end
  
  it "should capture output for a test case" do
    t = example_failing_report do |parser|
      parser << '2012-02-17 15:03:06.521 otest[24979:7803] line1'
      parser << '2012-02-17 15:03:06.521 otest[24979:7803] line2'
      parser << '2012-02-17 15:03:06.521 otest[24979:7803] line3'
      parser << '2012-02-17 15:03:06.521 otest[24979:7803] line4'
      parser << '/Some/Path/To/Test.m:1234: error: -[AnExampleTestSuite aFailingTest] : This is an error message'
    end
    
    failure = t.reports.first.tests[0]
    failure.passed?.should==false
    failure.errors.count.should==1
    failure.errors[0][:data].count.should==4
    failure.errors[0][:data][0].should=~/line1/
    failure.errors[0][:data][1].should=~/line2/
    failure.errors[0][:data][2].should=~/line3/
    failure.errors[0][:data][3].should=~/line4/
  end
  
  it "should capture errors reported during a test" do
    t = example_failing_report do |parser|
      parser << '/Some/Path/To/Test.m:1234: error: -[AnExampleTestSuite aFailingTest] : This is an error message'
    end
    
    failure = t.reports.first.tests[0]
    failure.passed?.should==false
    failure.errors.count.should==1
    failure.errors[0][:message].should=='This is an error message'
    failure.errors[0][:location].should=='/Some/Path/To/Test.m:1234'
  end
  
  it "should create a test case" do 
    t = example_report
    t.reports.count.should==1
    t.reports.first.name.should=="AnExampleTestSuite"
    t.reports.first.start_time.should==Time.parse("2012-02-10 00:37:04 +0000")
    t.reports.first.end_time.should==Time.parse("2012-02-10 00:37:04 +0000")
  end
  
  it "should detect a passing report" do
    t = example_report
    t.should be_succeed
    t.should_not be_failed
  end
  
  it "should detect a failing report" do 
    t = example_failing_report
    t.should_not be_succeed
    t.should be_failed
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
  
  it "should capture failed build" do
    t = Xcode::Test::OCUnitReportParser.new
    t << "Run test suite AnExampleTestSuite"
    t << "Test Suite 'AnExampleTestSuite' started at 2012-02-10 00:37:04 +0000"
    t << "Run test case anExampleTest1"
    t << "Test Case '-[AnExampleTestSuite anExampleTest1]' started."
    t << "/Path/To/Project/Tests/YPKeywordSuggestHandlerTest.m:45: error: -[AnExampleTestSuite anExampleTest1] : 'An example test spec' [FAILED], mock received unexpected message -setSuspended: 1 "
    t << "/Developer/Tools/RunPlatformUnitTests.include: line 415: 32225 Bus error: 10           \"${THIN_TEST_RIG}\" \"${OTHER_TEST_FLAGS}\" \"${TEST_BUNDLE_PATH}\""
    t << "/Developer/Tools/RunPlatformUnitTests.include:451: error: Test rig '/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/Developer/usr/bin/otest' exited abnormally with code 138 (it may have crashed)."
    
    t.flush
    t.failed?.should==true
    t.finished?.should==true
    failure = t.reports.first.tests[0]
    failure.passed?.should==false
    failure.data.count.should==2
    failure.data[0].should=~/32225 Bus error: 10/
    failure.data[1].should=~/Test rig/
  end

  it "should not fail due to Unicode characters" do
    expect do
      parser = Xcode::Test::OCUnitReportParser.new
      string = "2012-04-09 16:56:32.682 otest[81203:7803] E restkit.object_mapping:RKObjectMappingOperation.m:248 Validation failed while mapping attribute at key path boolString to value FAIL. Error: The operation couldn\xE2\x80\x99t be completed. (org.restkit.RestKit.ErrorDomain error 1003.)"
      string.force_encoding("US-ASCII")
      parser << string
    end.not_to raise_error
  end

  context "Junit output" do
    
    it "should write out reports in junit format" do 
      report_dir = "#{File.dirname(__FILE__)}/test-reports"
      FileUtils.rm_rf report_dir
    
      t = example_report do |t|
        t.formatters = []
        t.add_formatter :junit, report_dir
      end
    
      files = Dir["#{report_dir}/*.xml"]
      files.count.should==1
      files.first.should=~/TEST-AnExampleTestSuite.xml$/
    
      # FIXME: parse the report
    end
    
  end
  
end