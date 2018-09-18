module GroupBuzz
  class SlackMessagePreparer

    GROUPBUZZ_DISCUSSION_FROM_SUBJECT = "Discussion from"
    GROUPBUZZ_RECENT_DISCUSSIONS_HEADER = "Recent Discussions"
    GROUPBUZZ_REPLY_HEADER_LINE = "Please REPLY ABOVE THIS LINE to respond by email."
    GROUPBUZZ_TOPIC_PREAMBLE = "Follow this topic if you would like to be notified of new posts in this discussion: "
    GROUPBUZZ_SUBSCRIBE_URL_PART = "subscribe"
    GROUPBUZZ_SENDER_VIA_SUFFIX = " via GroupBuzz"
    MARKER_EMBED_REMOVED = "!EMBED_REMOVED!"
    LINE_BREAK_SEGMENT = "\r\n"

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
        puts "#{Time.now} - GroupBuzz::SlackMessagePreparer.prepare()"
        puts "#{Time.now} - posted_message:\n#{posted_message}"
      end

      raw_email_body = posted_message['email_body']
      raw_subject = posted_message['subject']

      return false, {} if is_digest_email?(raw_email_body, raw_subject)

      topic_preamble_index, groupbuzz_link = prepare_groupbuzz_link(raw_email_body)
      raw_email_body = raw_email_body[0, topic_preamble_index] if groupbuzz_link
      sender_name = prepare_sender_name(posted_message['sender_name'])
      subject = prepare_subject(raw_subject, sender_name, groupbuzz_link)
      
      body_text = prepare_body_text(raw_email_body)

      return true, message_hash(sender_name, subject, body_text)
    end
  
    private

    def message_hash(sender_name, subject, body_text)
      # Note: top-level 'text' displays the same as attachments[0].pretext (outside the attachment, same font size)
      {
        attachments: [
          {
            pretext: subject,
            author_name: sender_name,
            text: body_text
          }
        ]
      }
    end

    def is_digest_email?(email_body, subject)
      return ((subject.include? GROUPBUZZ_DISCUSSION_FROM_SUBJECT)||
              (email_body.include? GROUPBUZZ_RECENT_DISCUSSIONS_HEADER))
    end

    def strip_groupbuzz_stuff(text)
      text = text.gsub(GROUPBUZZ_REPLY_HEADER_LINE, "")
      text = remove_embedded_images(text)
  
      # TODO - 20180911 might not need this anymore?
      #remove_embed_removed_marker(text)
    end

    def prepare_sender_name(sender_name)
      sender_name.delete('"').gsub(GROUPBUZZ_SENDER_VIA_SUFFIX, '')
    end

    def prepare_subject(text, sender, groupbuzz_link)
      subject = text.gsub(@message_subject_prefix, '')
      return groupbuzz_link ?
        "<#{groupbuzz_link}|#{subject}>" :
        "#{subject}"  
    end

    def prepare_body_text(text)
      # If enabled, stripping all new lines because we don't care about it (line formatting) for a preview/snippet.
      body_text = @strip_new_lines ?
        strip_new_lines(text) :
        text

      # Remove all embedded images and the header (reply to)/footer(thread)
      body_text = strip_groupbuzz_stuff(body_text)
      # Strip any newlines before that are left over from removing the GB reply header line
      body_text.lstrip!

      body_text = Slack::Notifier::Util::LinkFormatter.format(body_text)

      body_text = convert_to_markdown_bold(body_text)

      pre_truncate_length = body_text.length
      body_text = truncate_text(body_text, @truncate_lines, @truncate_length)

      return pre_truncate_length >= @truncate_length ?
       "#{body_text}…" : body_text
    end

    def prepare_groupbuzz_link(text)
      topic_preamble_index = text.index(GROUPBUZZ_TOPIC_PREAMBLE) 
      return nil, nil unless topic_preamble_index
      link_start_at = topic_preamble_index + GROUPBUZZ_TOPIC_PREAMBLE.length
      return topic_preamble_index, 
        text[link_start_at, text.length - (link_start_at + GROUPBUZZ_SUBSCRIBE_URL_PART.length)].gsub('http', 'https')      
    end

    # See https://stackoverflow.com/questions/9107658/regex-to-strip-r-and-n-or-r-n
    # and https://stackoverflow.com/questions/26767949/regular-expression-where-pattern-is-repeated-ruby-on-rails
    def strip_new_lines(text)
      text.gsub(/(\r?\n)+/, ' ')
    end

    def truncate_text(text, max_distinct_lines, max_text_length)
      by_lines_truncated_length, by_lines_truncated = truncate_text_distinct_lines(text, max_distinct_lines)

      return by_lines_truncated if by_lines_truncated_length <= max_text_length

      # Return original text if less than max length. 
      # This is after the by lines truncation to allow haiku-style emails to be truncated.
      return text if text.length <= max_text_length

      # Truncate on word boundaries. Will currently break on punctuation like apostrophe though.

      # Match whitespace https://stackoverflow.com/questions/159118/how-do-i-match-any-character-across-multiple-lines-in-a-regular-expression/159140
      # Use dynamic variable in quantifier - https://stackoverflow.com/questions/6722145/how-can-i-interpolate-a-variable-in-a-ruby-regex
      text.match(/(.|\n){1,#{max_text_length}}.*?(?:\b|$)/i)[0]
    end

    # Truncate text based on number of distinct lines
    # This method cannot currently distinguish between a single line break and more than one line break (blank lines)
    def truncate_text_distinct_lines(text, max_distinct_lines)
      text_segments_truncated = []
      count_line_breaks = 0

      text_segments = text.split(/(\r?\n)+/)

      text_segments.each_with_index do |text_segment, index|
        if (text_segment == LINE_BREAK_SEGMENT)
          count_line_breaks += 1
        end
        if count_line_breaks == max_distinct_lines
          break
        end
        text_segments_truncated << text_segment
      end

      text_only_segments = text_segments_truncated.reject{|segment| segment == LINE_BREAK_SEGMENT}
      text_only_segments_length = text_only_segments.inject(0){|sum, segment| sum + segment.length }

      return text_only_segments_length, text_segments_truncated.join('')
    end

    # Hacked together convert **<words/spaces>** to *<word(s)/space(s)>
    # Regexp from https://gist.github.com/jbroadway/2836900
    # Method scaffold from https://github.com/aziflaj/md2html/blob/master/md2html.rb
    def convert_to_markdown_bold(text)
      match_count = 0
      text.gsub(/(\*\*|__)(.*?)\1/) do |strong|
        strong.gsub('**', '*')
      end
    end

    # I did not write the original method!
    # Modified from:
    # https://stackoverflow.com/questions/9268407/how-to-convert-markdown-style-links-using-regex
    # Note: This leaves 3 spaces, 1 before and 2 after the to-replace marker: MARKER_EMBED_REMOVED
    def remove_embedded_images(text)
      text.gsub %r{
        \!         # Literal ! (for ![giphy_whatever.gif])
        \[         # Literal opening bracket
          (        # Capture what we find in here
            [^\]]+ # One or more characters other than close bracket
          )        # Stop capturing
        \]         # Literal closing bracket
        \(//[^)]+uploads.groupbuzz.io         # Literal opening parenthesis, 1 or more characters other than close, groupbuzz upload hostname
          (        # Capture what we find in here
            [^)]+  # One or more characters other than close parenthesis
          )        # Stop capturing
        \)         # Literal closing parenthesis
      }x, ''
    end

    # TODO - 20180911 might not need this anymore?
    # Since the hacked-up remove_embedded_images leaves undesired spaces before and after, remove those spaces here
    def remove_embed_removed_marker(text)
      text.gsub(" #{MARKER_EMBED_REMOVED}  ", '')
    end

  end
end