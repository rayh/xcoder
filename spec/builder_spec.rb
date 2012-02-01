require 'rspec'
require 'xcoder'

describe Xcode::Builder do 
  
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
    
    context "when additional parameters have been specified" do
      
      it "should add new parameters" do
        
        expected_build_parameters = default_build_parameters + [ "-additionalparameter=value" ]
        
        Xcode::Shell.should_receive(:execute).with(expected_build_parameters)
        
        subject.build do |parameters|
          parameters << "-additionalparameter=value"
        end
        
      end
      
      let(:overridden_build_parameters) do
        [ "xcodebuild", 
          "-sdk newiossdk", 
          "-project \"#{configuration.target.project.path}\"", 
          "-target \"#{configuration.target.name}\"", 
          "-configuration \"#{configuration.name}\"", 
          "OBJROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"" ]
      end
      
      it "should override existing parameters" do
        
        Xcode::Shell.should_receive(:execute).with(overridden_build_parameters)
        
        subject.build do |parameters|
          parameters << "-sdk newiossdk"
        end
        
      end
      
      it "should support additional environment variables" do
        
        expected_build_parameters = default_build_parameters + [ "ENVIRONMENTVARIABLE=NEWVARIABLE" ]
        
        Xcode::Shell.should_receive(:execute).with(expected_build_parameters)
        
        subject.build do |parameters|
          parameters << "ENVIRONMENTVARIABLE=NEWVARIABLE"
        end
        
      end

    end
    
  end
  
end