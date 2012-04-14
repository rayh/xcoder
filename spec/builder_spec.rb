require_relative 'spec_helper'

describe Xcode::Builder do 
  
  context "when using a builder built from a configuration" do

    let(:configuration) { Xcode.project('TestProject').target('TestProject').config('Debug') }

    let(:subject) { configuration.builder }

    describe "#build" do
      
      let(:default_build_parameters) do
        [ "xcodebuild", 
          "-sdk #{configuration.target.project.sdk}", 
          "-project \"#{configuration.target.project.path}\"", 
          "-target \"#{configuration.target.name}\"", 
          "-configuration \"#{configuration.name}\"", 
          "OBJROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"" ]
      end

      it "should build the project with the default parameters" do
        Xcode::Shell.should_receive(:execute).with(default_build_parameters)
        subject.build
      end
      
      it "should allow the override of the sdk" do
        expected = default_build_parameters
        expected[1] = '-sdk macosx10.7'
        Xcode::Shell.should_receive(:execute).with(expected)
        subject.build :sdk => 'macosx10.7'
      end
      
    end
    
    describe "#testflight" do
      
      let(:testflight_parameters) do 
        ['curl',
        "--proxy http://proxyhost:8080",
        "-X POST http://testflightapp.com/api/builds.json",
        "-F file=@\"#{subject.ipa_path}\"",
        "-F dsym=@\"#{subject.dsym_zip_path}\"",
        "-F api_token='api_token'",
        "-F team_token='team_token'",
        "-F notes=\"some notes\"",
        "-F notify=True",
        "-F distribution_lists='List1,List2'"]
      end
    
      it "should upload ipa and dsym to testflight" do 
        subject.build.package
        
        Xcode::Shell.should_receive(:execute).with(testflight_parameters).and_return(['{}'])
        subject.testflight("api_token", "team_token") do |tf|
          tf.proxy = "http://proxyhost:8080"
          tf.notes = "some notes"
          tf.lists << "List1"
          tf.lists << "List2"
        end
      
      end
    end
    
    describe "#test" do
      
      let(:configuration) do
        Xcode.project('TestProject').target('TestProjectTests').config('Debug')
      end
      
      let(:default_test_parameters) do
        [ "xcodebuild", 
          "-sdk iphonesimulator", 
          "-project \"#{configuration.target.project.path}\"", 
          "-target \"#{configuration.target.name}\"", 
          "-configuration \"#{configuration.name}\"", 
          "OBJROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"",
          "TEST_AFTER_BUILD=YES",
          # "TEST_HOST=''",
          ]
      end
      
      it "should be able to run the test target" do
        Xcode::Shell.should_receive(:execute).with(default_test_parameters, false)
        subject.test
      end
      
      it "should allow the override of the sdk" do
        expected = default_test_parameters
        expected[1] = '-sdk macosx10.7'
        Xcode::Shell.should_receive(:execute).with(expected, false)
        subject.test :sdk => 'macosx10.7'
      end
      
      it "should not exit when test failed" do
        Xcode::Shell.stub(:execute)
        fake_parser = stub(:parser)
        fake_parser.stub(:failed? => true)
        fake_parser.stub(:flush)
        Xcode::Test::Parsers::OCUnitParser.stub(:new => fake_parser)
        subject.test
      end
      
    end

    describe "#clean" do

      let(:default_clean_parameters) do
        [ "xcodebuild", 
          "-project \"#{configuration.target.project.path}\"", 
          "-sdk iphoneos",
          "-target \"#{configuration.target.name}\"", 
          "-configuration \"#{configuration.name}\"", 
          "OBJROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"",
          "clean" ]
      end


      it "should clean the project with the default parameter" do
        Xcode::Shell.should_receive(:execute).with(default_clean_parameters)
        subject.clean
      end

    end

  end
  
  context "when using a builder built from a scheme" do

    let(:scheme) { Xcode.project('TestProject').scheme('TestProject') }
    
    let(:subject) { scheme.builder }

    describe "#build" do
      
      let(:default_build_parameters) do
        [ "xcodebuild",
          "-sdk iphoneos",
          "-project \"#{scheme.project.path}\"",
          "-scheme \"#{scheme.name}\"",
          "OBJROOT=\"#{File.dirname(scheme.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(scheme.project.path)}/build/\"" ]
      end

      it "should build the project with the default parameters" do
        Xcode::Shell.should_receive(:execute).with(default_build_parameters)
        subject.build
      end
      
    end
    
    describe "#clean" do

      let(:default_clean_parameters) do
        [ "xcodebuild",
          "-project \"#{scheme.project.path}\"",
          "-sdk iphoneos",
          "-scheme \"#{scheme.name}\"",
          "OBJROOT=\"#{File.dirname(scheme.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(scheme.project.path)}/build/\"",
          "clean" ]
      end


      it "should clean the project with the default parameter" do
        Xcode::Shell.should_receive(:execute).with(default_clean_parameters)
        subject.clean
      end

    end

  end
  
end