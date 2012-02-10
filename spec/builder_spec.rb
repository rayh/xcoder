require 'rspec'
require 'xcoder'

describe Xcode::Builder do 
  
  context "when using a builder built from a configuration" do

    let(:configuration) { Xcode.project('TestProject').target('TestProject').config('Debug') }

    let(:subject) { configuration.builder }

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