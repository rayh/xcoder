require 'rspec'
require 'xcoder'

describe Xcode::Target do 
  before do
    @target = Xcode.project('TestProject').target('TestProject')
  end
  
  it "should parse the name" do 
    @target.name.should=="TestProject"
    @target.productName.should=="TestProject"
  end
  
  it "should return a list of configs" do
    @target.configs.size.should==2
    @target.configs[0].name.should=="Debug"
    @target.configs[1].name.should=="Release"
  end
  
  it "should return the config by name" do
    config = @target.config('Debug')
    config.should_not be_nil
    config.name.should=='Debug'
  end
end