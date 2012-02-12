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
          "TEST_HOST=''",]
      end
      
      it "should be able to run the test target" do
        Xcode::Shell.should_receive(:execute).with(default_test_parameters, false)
        subject.test
      end
      
    end

    describe "#clean" do

      let(:default_clean_parameters) do
        [ "xcodebuild", 
          "-project \"#{configuration.target.project.path}\"", 
          "-target \"#{configuration.target.name}\"", 
          "-configuration \"#{configuration.name}\"", 
          "OBJROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"",
          "clean" ]
      end


      it "should clean the project with the default parametesr" do
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
          "-scheme #{scheme.name}",
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
          "-scheme #{scheme.name}",
          "OBJROOT=\"#{File.dirname(scheme.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(scheme.project.path)}/build/\"",
          "clean" ]
      end


      it "should clean the project with the default parametesr" do
        Xcode::Shell.should_receive(:execute).with(default_clean_parameters)
        subject.clean
      end

    end

  end
  
end