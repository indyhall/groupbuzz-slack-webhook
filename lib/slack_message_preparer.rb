module GroupBuzz
  class SlackMessagePreparer

    GROUPBUZZ_REPLY_HEADER_LINE = "Please REPLY ABOVE THIS LINE to respond by email."
    GROUPBUZZ_TOPIC_PREAMBLE = "Follow this topic if you would like to be notified of new posts in this discussion: "
    GROUPBUZZ_SUBSCRIBE_URL_PART = "subscribe"
    GROUPBUZZ_SENDER_VIA_SUFFIX = " via GroupBuzz"
    MARKER_EMBED_REMOVED = "!EMBED_REMOVED!"
    LINE_BREAK_SEGMENT = "\r\n"

    attr_accessor :strip_new_lines
    attr_accessor :truncate_length
    attr_accessor :truncate_lines

    def initialize
      @truncate_length = GroupBuzz::SettingsHolder.settings[:message_truncate_length]
      @truncate_lines = GroupBuzz::SettingsHolder.settings[:message_truncate_lines]
      @message_subject_prefix = GroupBuzz::SettingsHolder.settings[:message_subject_prefix]
      @strip_new_lines = GroupBuzz::SettingsHolder.settings[:message_strip_new_lines]
    end

    def prepare(posted_message)
      raw_email_body = posted_message['email_body']

      topic_preamble_index, groupbuzz_link = prepare_groupbuzz_link(raw_email_body)
      raw_email_body = raw_email_body[0, topic_preamble_index] if groupbuzz_link
      sender_name = prepare_sender_name(posted_message['sender_name'])
      subject = prepare_subject(posted_message['subject'], sender_name, groupbuzz_link)
      
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

    def strip_groupbuzz_stuff(text)
      text = text.gsub(GROUPBUZZ_REPLY_HEADER_LINE, "")
      text = remove_embedded_images(text)
      #remove_embed_removed_marker(text)
    end

    def prepare_sender_name(sender_name)
      sender_name.delete('"').gsub(GROUPBUZZ_SENDER_VIA_SUFFIX, '')
    end

    def prepare_subject(text, sender, groupbuzz_link)
#      sender_prefix = "#{sender} - "
      sender_prefix = "" # move to attachments
      subject = text.gsub(@message_subject_prefix, '')
      return groupbuzz_link ?
        "#{sender_prefix}<#{groupbuzz_link}|#{subject}>" :
        "#{sender_prefix}#{subject}"  
    end

    def prepare_body_text(text)
      # If enabled, stripping all new lines because we don't care about it (line formatting) for a preview/snippet.
      body_text = @strip_new_lines ?
        strip_new_lines(text) :
        text

      # Remove all embedded images and the header (reply to)/footer(thread)
      body_text = strip_groupbuzz_stuff(body_text)

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

      return text if text.length <= max_text_length

      # See https://stackoverflow.com/questions/8714045/truncate-a-string-without-cut-in-the-middle-of-a-word-in-rails
      text.match(/^.{0,#{max_text_length}}\b/)[0]
    end

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

    # Since the hacked-up remove_embedded_images leaves undesired spaces before and after, remove those spaces here
    # TODO - 20180911 might not need this anymore?
    def remove_embed_removed_marker(text)
      text.gsub(" #{MARKER_EMBED_REMOVED}  ", '')
    end

  end
end