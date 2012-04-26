require_relative 'spec_helper'

describe Xcode::PLUTILProjectParser do
  
  let(:subject) { Xcode::PLUTILProjectParser }
  
  describe "#parse" do
    
    context "when the file exists" do
      
      let(:project_filet_that_exists) { "A Project File That Exists" }
      
      it "should return the parsed content" do
        
        subject.should_receive(:open_project_file).with(project_filet_that_exists).and_return(:raw_content)
        
        Plist.should_receive(:parse_xml).with(:raw_content).and_return(:valid_content)
        
        subject.parse(project_filet_that_exists).should eq(:valid_content)
        
        
      end
    end
    
    context "when the file does not exist" do
      
      let(:project_file_does_not_exist) { "A Project File Does Not Exists" }
      
      it "should raise an exception" do
        
          subject.should_receive(:open_project_file).with(project_file_does_not_exist)
          
          Plist.should_receive(:parse_xml).and_return(nil)
          
        expect {
          
          subject.parse(project_file_does_not_exist)
          
        }.to raise_error
        
        
      end
    end
    
  end
  
end