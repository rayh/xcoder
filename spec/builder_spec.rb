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
    
  end
  
end