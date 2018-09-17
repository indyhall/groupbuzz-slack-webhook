require 'spec_helper'

describe GroupBuzz::TopicProcessor do

  context "extract GB topic link" do

    it 'should extract the HTTP GB topic link and not convert it to HTTPS if the email body footer exists' do
      topic_link = topic_link(GroupBuzz::MessageConstants::HTTP_PROTOCOL)
      body_text = body_with_footer(topic_link)
      check_extracted_groupbuzz_link(body_text, topic_link(GroupBuzz::MessageConstants::HTTP_PROTOCOL))
    end

    it 'should extract the HTTPS GB topic link as-is if the email body footer exists' do
      topic_link = topic_link(GroupBuzz::MessageConstants::HTTPS_PROTOCOL)
      body_text = body_with_footer(topic_link)
      check_extracted_groupbuzz_link(body_text, topic_link(GroupBuzz::MessageConstants::HTTPS_PROTOCOL))
    end

    it 'should not extract a GB topic link if the email body does not contain the footer' do
      topic_link = topic_link(GroupBuzz::MessageConstants::HTTPS_PROTOCOL)
      check_extracted_groupbuzz_link("No footer #{topic_link}", nil)
    end

    it 'should get the index of the footer preamble if the email body footer exists' do
      body_content = "1234567890"
      topic_preamble_index, extracted_link = extract_groupbuzz_link("#{body_content}#{GroupBuzz::MessageConstants::GROUPBUZZ_TOPIC_PREAMBLE}")
      expect(topic_preamble_index).to eq(body_content.length)
    end

    it 'should get the index of the footer preamble if the email body footer exists' do
      topic_preamble_index, extracted_link = extract_groupbuzz_link("no footer")
      expect(topic_preamble_index).to be_nil
    end
 
  end

  def check_extracted_groupbuzz_link(body_text, expected_link)
    topic_preamble_index, extracted_link = extract_groupbuzz_link(body_text)
    expect(extracted_link).to eq(expected_link)
  end

  def extract_groupbuzz_link(body_text)
    return  topic_processor.extract_groupbuzz_link(body_text)    
  end

  def body_with_footer(topic_link)
    topic_subscribe_link = "#{topic_link}subscribe"
    "\r\n\r\n\r\n#{GroupBuzz::MessageConstants::GROUPBUZZ_TOPIC_PREAMBLE}#{topic_subscribe_link}"
  end

  def topic_link(protocol)
    "#{protocol}://indyhall.groupbuzz.io/topics/16997-next-week-is-member-photo-week/"
  end

  def topic_processor
    @topic_processor ||= GroupBuzz::TopicProcessor.new()
  end

end
