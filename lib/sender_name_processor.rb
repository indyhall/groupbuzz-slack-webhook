require_relative 'message_constants'

module GroupBuzz
  class SenderNameProcessor
    include GroupBuzz::MessageConstants

    def extract_sender_name(sender_name)
      sender_name.delete('"').gsub(GROUPBUZZ_SENDER_VIA_SUFFIX, '')
    end

  end
end