require 'rspec'
require 'xcoder'

describe Xcode::Scheme do 
  before do
    @scheme = Xcode.project('TestProject').scheme('TestProject')
  end
  
  it "should parse the name" do 
    @scheme.name.should=="TestProject"
  end
  
  it "should be able to build" do
    builder = @scheme.builder
    builder.clean
    builder.build
    File.exists?(builder.app_path).should==true
    File.exists?(builder.dsym_path).should==true
  end
  
  it "should be able to package" do
    builder = @scheme.builder
    builder.clean
    builder.build
    builder.package
    File.exists?(builder.dsym_zip_path).should==true
    File.exists?(builder.ipa_path).should==true
  end
end