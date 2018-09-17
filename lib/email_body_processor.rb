require 'message_constants'

module GroupBuzz
  class EmailBodyProcessor
    include GroupBuzz::MessageConstants

    def remove_reply_header(body)
      body.gsub(GROUPBUZZ_REPLY_HEADER_LINE, "")
    end

    def remove_starting_line_breaks(body)
      body.lstrip
    end

    def remove_ending_line_breaks(body)
      body.rstrip
    end

    def remove_follow_topic_footer(body)
      topic_preamble_index = body.index(GROUPBUZZ_TOPIC_PREAMBLE) 
      return body unless topic_preamble_index

      body[0, topic_preamble_index]
    end

  end
end