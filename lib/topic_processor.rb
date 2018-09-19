require_relative 'message_constants'

module GroupBuzz
  class TopicProcessor
    include GroupBuzz::MessageConstants

    def extract_groupbuzz_link(text)
      topic_preamble_index = text.index(GROUPBUZZ_TOPIC_PREAMBLE) 
      return nil, nil unless topic_preamble_index # TODO - This should probably throw an exception instead of returning nil

      link_start_at = topic_preamble_index + GROUPBUZZ_TOPIC_PREAMBLE.length
      extracted_link = text[link_start_at, text.length - (link_start_at + GROUPBUZZ_SUBSCRIBE_URL_PART.length)] 
      return topic_preamble_index, extracted_link
    end

  end
end