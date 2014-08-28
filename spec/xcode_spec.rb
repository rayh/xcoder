require_relative "spec_helper"

describe Xcode do

  let(:subject) { Xcode }

  describe "#projects" do

    context "when there is a project within the current directory" do

      let(:subject) { Xcode.projects }

      it "should find the project" do
        puts subject.map {|p| p.name}
        expect(subject.size).to eq 1
        expect(subject.first.name).to eq "TestProject"
      end

    end

  end

  describe "#project" do
    context "when the target project exists" do
      context "when fetching the project by name" do

        let(:subject) { Xcode.project 'TestProject' }

        it "should find the project" do
          expect(subject).not_to be_nil
        end

      end

      context "when fetching the project by path" do

        let(:subject) { Xcode.project "#{File.dirname(__FILE__)}/TestProject/TestProject.xcodeproj" }

        it "should find the project" do
          expect(subject).not_to be_nil
        end

      end
    end

    context "when the target project does not exist" do

      let(:subject) { Xcode.project 'DoesNotExistProject' }

      it "should raise an error" do
        expect { subject }.to raise_error
      end

    end

  end

end