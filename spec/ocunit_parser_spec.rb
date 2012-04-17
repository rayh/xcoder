require 'rspec'
require 'xcoder'

require 'xcode/test/parsers/ocunit_parser'

describe Xcode::Test::Parsers::OCUnitParser do 
  
  let :parser do
    Xcode::Test::Parsers::OCUnitParser.new
  end
  
  let :example_report do
    parser << "Run test suite AnExampleTestSuite"
    parser << "Test Suite 'AnExampleTestSuite' started at 2012-02-10 00:37:04 +0000"
    
    parser << "Run test case anExampleTest1"
    parser << "Test Case '-[AnExampleTestSuite anExampleTest1]' started."
    parser << "Test Case '-[AnExampleTestSuite anExampleTest1]' passed (0.003 seconds)."

    parser << "Run test case anExampleTest2"
    parser << "Test Case '-[AnExampleTestSuite anExampleTest2]' started."
    parser << "Test Case '-[AnExampleTestSuite anExampleTest2]' passed (0.003 seconds)."
    
    parser << "Test Suite 'AnExampleTestSuite' finished at 2012-02-10 00:37:04 +0000."
    parser << "Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds"
    
    parser.report
  end
  
  let :example_failing_report do
    parser << "Run test suite AnExampleTestSuite"
    parser << "Test Suite 'AnExampleTestSuite' started at 2012-02-10 00:37:04 +0000"
    parser << "Test Case '-[AnExampleTestSuite aFailingTest]' started."
    
    parser << '2012-02-17 15:03:06.521 otest[24979:7803] line1'
    parser << '2012-02-17 15:03:06.521 otest[24979:7803] line2'
    parser << '2012-02-17 15:03:06.521 otest[24979:7803] line3'
    parser << '2012-02-17 15:03:06.521 otest[24979:7803] line4'
    parser << '/Some/Path/To/Test.m:1234: error: -[AnExampleTestSuite aFailingTest] : This is an error message'
    
    parser << "Test Case '-[AnExampleTestSuite aFailingTest]' failed (2 seconds)."
    parser << "Test Suite 'AnExampleTestSuite' finished at 2012-02-10 00:37:04 +0000."
    parser << "Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds"
    
    parser.report
  end
  
  it "should start the report" do
    parser.report.start_time.should be_nil
    parser << "Test Suite '/Users/blake/Projects/RestKit/RestKit/Build/Products/Debug-iphonesimulator/RestKitTests.octest(Tests)' started at 2012-04-17 01:36:20 +0000\n"
    parser.report.start_time.should_not be_nil
  end
  
  it "should capture output for a test case" do
    
    failure = example_failing_report.suites.first.tests[0]
    failure.passed?.should==false
    failure.errors.count.should==1
    failure.errors[0][:data].count.should==4
    failure.errors[0][:data][0].should=~/line1/
    failure.errors[0][:data][1].should=~/line2/
    failure.errors[0][:data][2].should=~/line3/
    failure.errors[0][:data][3].should=~/line4/
  end
  
  it "should capture errors reported during a test" do
    failure = example_failing_report.suites.first.tests[0]
    failure.passed?.should==false
    failure.errors.count.should==1
    failure.errors[0][:message].should=='This is an error message'
    failure.errors[0][:location].should=='/Some/Path/To/Test.m:1234'
  end
  
  it "should create a test case" do 
    t = example_report.suites
    t.count.should==1
    t.first.name.should=="AnExampleTestSuite"
    t.first.start_time.should==Time.parse("2012-02-10 00:37:04 +0000")
    t.first.end_time.should==Time.parse("2012-02-10 00:37:04 +0000")
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
    t.suites.first.total_failed_tests.should==1
  end
  
  it "should create a test case with some tests" do 
    t = example_report.suites
      
    t.count.should==1
    t.first.tests.count.should==2
    t.first.tests[0].name.should=='anExampleTest1'
    t.first.tests[0].time.should==0.003
    t.first.tests[0].passed?.should==true
    
    t.first.tests[1].name.should=='anExampleTest2'
    t.first.tests[1].time.should==0.003
    t.first.tests[1].passed?.should==true
  end
  
  it "should capture failed build" do
    parser << "Run test suite AnExampleTestSuite"
    parser << "Test Suite 'AnExampleTestSuite' started at 2012-02-10 00:37:04 +0000"
    parser << "Run test case anExampleTest1"
    parser << "Test Case '-[AnExampleTestSuite anExampleTest1]' started."
    parser << "/Path/To/Project/Tests/YPKeywordSuggestHandlerTest.m:45: error: -[AnExampleTestSuite anExampleTest1] : 'An example test spec' [FAILED], mock received unexpected message -setSuspended: 1 "
    parser << "/Developer/Tools/RunPlatformUnitTests.include: line 415: 32225 Bus error: 10           \"${THIN_TEST_RIG}\" \"${OTHER_TEST_FLAGS}\" \"${TEST_BUNDLE_PATH}\""
    parser << "/Developer/Tools/RunPlatformUnitTests.include:451: error: Test rig '/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/Developer/usr/bin/otest' exited abnormally with code 138 (it may have crashed)."
  
    parser.flush
    
    report = parser.report
    
    report.failed?.should==true
    report.finished?.should==true
    failure = report.suites.first.tests[0]
    failure.passed?.should==false
    failure.data.count.should==2
    failure.data[0].should=~/32225 Bus error: 10/
    failure.data[1].should=~/Test rig/
  end
  
  context "encoding" do
    it "should not fail due to Unicode characters" do
      expect do
        string = "2012-04-09 16:56:32.682 otest[81203:7803] E restkit.object_mapping:RKObjectMappingOperation.m:248 Validation failed while mapping attribute at key path boolString to value FAIL. Error: The operation couldn\xE2\x80\x99t be completed. (org.restkit.RestKit.ErrorDomain error 1003.)"
        string.force_encoding("US-ASCII")
        parser << string
      end.not_to raise_error
    end
  end

  context "Junit output" do
    
    it "should write out reports in junit format" do 
      report_dir = "#{File.dirname(__FILE__)}/test-reports"
      FileUtils.rm_rf report_dir
    
      parser.report.add_formatter :junit, report_dir
      
      example_report
    
      files = Dir["#{report_dir}/*.xml"]
      files.count.should==1
      files.first.should=~/TEST-AnExampleTestSuite.xml$/
    
      # FIXME: parse the report
    end
    
  end
  
end