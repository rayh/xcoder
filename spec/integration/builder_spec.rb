require_relative '../spec_helper'

describe Xcode::Builder, :integration => true do
  
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
      
    end
  
  end
  
end
