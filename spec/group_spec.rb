require 'rspec'
require 'xcoder'

describe Xcode::PBXGroup do 

  let(:subject) { Xcode.project('../ios/ios.xcodeproj') }
  
  it "should add a group without error" do
    
    p subject.groups.children.last
    
    g = subject.groups.add_group 'Frank'
    puts g.identifier
    
    puts subject.targets.first.registry['objects'][g.identifier]

    p subject.registry['objects'][g.identifier]
    
    subject.save!
    
  end


end