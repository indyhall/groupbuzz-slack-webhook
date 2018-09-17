require 'spec_helper'

describe GroupBuzz::EmailBodyProcessor do

  DEFAULT_TOPIC_LINK = "http://indyhall.groupbuzz.io/topics/16997-next-week-is-member-photo-week/"

  context "removal" do

    it "should not strip out the GB message header if it is not there" do
      original = "\r\n\r\nThis is the first real sentence."
      modified = email_body_processor.remove_reply_header(original)
      expect(modified).to eq(original)
    end

    it "should strip out the GB message header and leave the starting new lines" do
      first_sentence = "\r\n\r\nThis is the first real sentence."
      original = "#{GroupBuzz::MessageConstants::GROUPBUZZ_REPLY_HEADER_LINE}#{first_sentence}"
      modified = email_body_processor.remove_reply_header(original)
      expect(modified).to eq(first_sentence)
    end

    it "should remove the starting new lines" do
      content = "This is the first real sentence."
      original = "\r\n\r\n#{content}"
      modified = email_body_processor.remove_starting_line_breaks(original)
      expect(modified).to eq(content)
    end

    it "should remove the ending new lines" do
      content = "\r\n\r\nThis is the first real sentence."
      original = "#{content}\r\n\r\n"
      modified = email_body_processor.remove_ending_line_breaks(original)
      expect(modified).to eq(content)
    end

    it "should remove the GB follow topic footer" do
      first_sentence = "This is sentence one. \r\n\r\nThis is sentence two."
      original = "#{first_sentence}#{GroupBuzz::MessageConstants::GROUPBUZZ_TOPIC_PREAMBLE} #{DEFAULT_TOPIC_LINK}"
      modified = email_body_processor.remove_follow_topic_footer(original)
      expect(modified).to eq(first_sentence)      
    end

    it "should not remove the GB follow topic footer if it is not there" do
      original = "This is sentence one. \r\n\r\nThis is sentence two. #{DEFAULT_TOPIC_LINK}"
      modified = email_body_processor.remove_follow_topic_footer(original)
      expect(modified).to eq(original)      
    end

  end

  def email_body_processor
    @email_body_processor ||= GroupBuzz::EmailBodyProcessor.new()
  end

end
