require_relative 'spec_helper'

describe Xcode::Registry do

  def self.is_identifier? value
    value =~ /^[0-9A-F]{24,}$/
  end

  describe "ClassMethods" do
    subject { described_class }

    describe "#is_identifier?" do
      context "when the value is valid hexadecimal 24 character length string" do
        context "when it is all uppercase" do
          let(:input) { "0123456789ABCDEF01234567" }

          it "should be an identifier" do
            subject.is_identifier?(input).should be_true
          end
        end

        context "when it uses lowercase characters" do
          let(:input) { "0123456789abcdef01234567" }

          it "should be an identifier" do
            subject.is_identifier?(input).should be_true
          end
        end
      end

      context "when the value is less than 24 characters" do
        let(:input) { "0123456789ABCDEF" }

        it "should not be an identifier" do
          subject.is_identifier?(input).should be_false
        end
      end

      context "when it contains other than hexadecimal characters" do
        let(:input) { "0123456789ABCDEFGHIJKLMNO" }

        it "should not be an identifier" do
          subject.is_identifier?(input).should be_false
        end
      end

    end
  end


end