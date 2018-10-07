require_relative 'message_constants'

module GroupBuzz
  class SlackMessagePreparerV2
    include GroupBuzz::MessageConstants

    attr_accessor :strip_new_lines
    attr_accessor :truncate_length
    attr_accessor :truncate_lines
    attr_accessor :original_message_debug_logging

    def initialize
      raise "Error! GROUPBUZZ_RELAY_SLACK_MESSAGE_SUBJECT_PREFIX not set as environment variable!" unless ENV['GROUPBUZZ_RELAY_SLACK_MESSAGE_SUBJECT_PREFIX']
      @message_subject_prefix = ENV['GROUPBUZZ_RELAY_SLACK_MESSAGE_SUBJECT_PREFIX']

      @truncate_length = GroupBuzz::SettingsHolder.settings[:message_truncate_length]
      @truncate_lines = GroupBuzz::SettingsHolder.settings[:message_truncate_lines]
      @strip_new_lines = GroupBuzz::SettingsHolder.settings[:message_strip_new_lines]
      @original_message_debug_logging = GroupBuzz::SettingsHolder.settings[:original_message_debug_logging]
    end

    def prepare(posted_message)
      if @original_message_debug_logging
        binding.pry
        puts "#{Time.now} - GroupBuzz::SlackMessagePreparerV2.prepare()"
        puts "#{Time.now} - posted_message:\n#{posted_message}"
      end

      raw_email_body = posted_message['email_body']
      raw_subject = posted_message['subject']
      raw_sender_name = posted_message['sender_name']

      return false, {} if is_digest_email?(raw_email_body, raw_subject)

      # TODO Handle the 3 special characters that Slack needs to be escaped
      # or is this handled by the Slack gem?
      return true, process_message(raw_email_body, raw_subject, raw_sender_name)
    end

    private

    def process_message(raw_email_body, raw_subject, raw_sender_name)
      sender_name = sender_name_processor.extract_sender_name(raw_sender_name)
      topic_preamble_index, extracted_link = topic_processor.extract_groupbuzz_link(raw_email_body)
      formatted_subject = subject_processor.format_subject(raw_subject, extracted_link)

      processed_email_body = process_email_body(raw_email_body)
    end

    def process_email_body(raw_email_body)
      # TODO - consider using a cleaner 'pipeline' process
      email_body = raw_email_body
      email_body = email_body_processor.remove_reply_header(email_body)
      email_body = email_body_processor.remove_follow_topic_footer(email_body)
      email_body = email_body_processor.remove_starting_line_breaks(email_body)
      email_body = email_body_processor.remove_ending_line_breaks(email_body)
      email_body = markdown_processor.remove_images(email_body)
      email_body = markdown_processor.format_double_bold(email_body)

      email_body
    end

    # TODO - this is a dupe of the method in SlackMessagePreparer(v1)
    def is_digest_email?(email_body, subject)
      return ((subject.include? GROUPBUZZ_DISCUSSION_FROM_SUBJECT)||
              (email_body.include? GROUPBUZZ_RECENT_DISCUSSIONS_HEADER))
    end    

    def email_body_processor
      @email_body_processor ||= GroupBuzz::EmailBodyProcessor.new
    end

    def markdown_processor
      @markdown_processor ||= GroupBuzz::MarkdownProcessor.new(keep_image_alt_text: false)
    end

    def sender_name_processor
      @sender_name_processor ||= GroupBuzz::SenderNameProcessor.new
    end

    def subject_processor
      @subject_processor ||= GroupBuzz::SubjectProcessor.new(@message_subject_prefix)
    end

    def topic_processor
      @topic_processor ||= GroupBuzz::TopicProcessor.new
    end

  end
end
