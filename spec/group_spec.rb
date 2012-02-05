require 'rspec'
require 'xcoder'

describe Xcode::PBXGroup do 

  let(:subject) { Xcode.project('../ios/ios.xcodeproj') }
  
  it "should add a group without error" do
    
    group = subject.groups.add_group 'Frank'
    #puts group.identifier
    
    # p subject.registry.object group.identifier
    
    file = subject.groups.add_file 'frank.txt'
    file2 = subject.groups.add_file 'frank-webber.txt'
    # p subject.registry.object file.identifier
    
    p subject.groups.children
    
    subject.save!
    
  end


end