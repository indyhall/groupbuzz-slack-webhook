require 'spec_helper'

describe GroupBuzz::SenderNameProcessor do

  context "extract GB sender name" do

    it "should extract the sender if GB formatted" do
      check_sender_name("\"Jane Doe\" via GroupBuzz", "Jane Doe")
    end

    it "should use a plain sender if there was no GB formatted sender name" do
      original_sender_name = "Plain Jane Doe"
      check_sender_name(original_sender_name, original_sender_name)
    end

  end

  def check_sender_name(sender_name, expected_sender_name)
    extracted_sender_name = sender_name_processor.extract_sender_name(sender_name)
    expect(extracted_sender_name).to eq(expected_sender_name)
  end

  def sender_name_processor
    @sender_name_processor ||= GroupBuzz::SenderNameProcessor.new()
  end

end
