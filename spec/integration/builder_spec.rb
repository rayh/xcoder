require_relative '../spec_helper'

describe Xcode::Builder, :integration => true do
  
  context "when using a builder built from a configuration" do
  
    describe "#build" do
    
      let(:configuration) { Xcode.project('TestProject').target('TestProject').config('Debug') }
      let(:subject) { configuration.builder }
    
      it "should be able to build" do
        subject.clean
        subject.build
        File.exists?(subject.app_path).should==true
        File.exists?(subject.dsym_path).should==true
      end
    
      it "should be able to package" do
        subject.clean
        subject.build
        subject.package
        File.exists?(subject.dsym_zip_path).should==true
        File.exists?(subject.ipa_path).should==true
      end
  
    end
    
    
    describe "#test" do
      
      let(:configuration) { Xcode.project('TestProject').target('TestProjectTests').config('Debug') }
      let(:subject) { configuration.builder }
      
      it "should be able to run unit tests" do
        subject.clean
        report = subject.test
        report.suites.count.should == 2
        
        tests = report.suites[1].tests
        tests.count.should==2
        tests[0].should be_passed
        tests[1].should be_failed

        tests = report.suites[0].tests
        tests.count.should==1
        tests[0].should be_passed
      end
    
    end
    
  end
  
  context "when using a builder built from a scheme" do

    let(:scheme) { Xcode.project('TestProject').scheme('TestProject') }
    
    let(:subject) { scheme.builder }

    describe "#build" do
      
      it "should be able to build" do
        subject.clean
        subject.build
        File.exists?(subject.app_path).should==true
        File.exists?(subject.dsym_path).should==true
      end
      
      it "should be able to package" do
        subject.clean
        subject.build
        subject.package
        File.exists?(subject.dsym_zip_path).should==true
        File.exists?(subject.ipa_path).should==true
      end
      
    end
    
    describe "#test" do
      
      it "should be able to run unit tests" do
        subject.clean
        report = subject.test
        report.suites.count.should == 2
        
        tests = report.suites[1].tests
        tests.count.should==2
        tests[0].should be_passed
        tests[1].should be_failed

        tests = report.suites[0].tests
        tests.count.should==1
        tests[0].should be_passed
      end
    
    end
  
  end
  
end
