require_relative 'message_constants'

module GroupBuzz
  class SubjectProcessor
    include GroupBuzz::MessageConstants

    def initialize(message_subject_prefix)
      @message_subject_prefix = message_subject_prefix
    end

    def format_subject(text, groupbuzz_link)
      subject = text.gsub(@message_subject_prefix, '')
      groupbuzz_link.gsub!(HTTP_PROTOCOL, HTTPS_PROTOCOL) unless 
        ((groupbuzz_link.nil?)||(groupbuzz_link.include? HTTPS_PROTOCOL))

      return groupbuzz_link ?
        "<#{groupbuzz_link}|#{subject}>" :
        "#{subject}"  
    end

  end
end