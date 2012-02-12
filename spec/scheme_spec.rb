require_relative 'spec_helper'

describe Xcode::Scheme do 
  before do
    @scheme = Xcode.project('TestProject').scheme('TestProject')
  end
  
  it "should parse the name" do 
    @scheme.name.should=="TestProject"
  end
  

end