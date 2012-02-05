require 'rspec'
require 'xcoder'

describe Xcode::Project do 
  it "should enumerate all projects in current directory" do 
    projects = Xcode.projects
    projects.size.should==1
    projects.first.name.should=="TestProject"
  end
  
  it "should fetch project by name" do 
    p = Xcode.project 'TestProject'
    p.should_not be_nil
  end
  
  it "should fetch project by name with extension and path" do 
    w = Xcode.project "#{File.dirname(__FILE__)}/TestProject/TestProject.xcodeproj"
    w.should_not be_nil
  end
  
  it "should have many targets" do 
    p = Xcode.project "TestProject"
    p.targets.size.should==2
    p.targets[0].name.should=="TestProject"
    p.targets[1].name.should=="TestProjectTests"
  end
  
  it "should get target by name" do 
    p = Xcode.project "TestProject"
    p.target('TestProjectTests').should_not be_nil
  end
  
  it "should have many schemes" do 
    p = Xcode.project "TestProject"
    p.schemes.size.should==1
    p.schemes.first.name.should=="TestProject"
  end
  
  it "should get scheme by name" do 
    p = Xcode.project "TestProject"
    p.scheme('TestProject').should_not be_nil
  end
  
  describe "#save!" do

    let(:subject) { Xcode.project('/Volumes/Glacier/git/ios/ios.xcodeproj') }
    
    it "should save correctly" do
      subject.save!
    end

    

  end
  
end