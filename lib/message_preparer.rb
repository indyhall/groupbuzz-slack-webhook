# TODO
# Need unit tests
module GroupBuzz
  class SlackMessagePreparer

    GROUPBUZZ_REPLY_HEADER_LINE = "Please REPLY ABOVE THIS LINE to respond by email."
    GROUPBUZZ_TOPIC_PREAMBLE = "Follow this topic if you would like to be notified of new posts in this discussion: "
    GROUPBUZZ_SUBSCRIBE_URL_PART = "subscribe"
    GROUPBUZZ_SENDER_VIA_SUFFIX = " via GroupBuzz"
    MARKER_EMBED_REMOVED = "!EMBED_REMOVED!"

    def initialize
      @truncate_length = GroupBuzz::SettingsHolder.settings[:message_truncate_length]
      @message_subject_prefix = GroupBuzz::SettingsHolder.settings[:message_subject_prefix]
    end

    def prepare(posted_message)
      raw_email_body = posted_message['email_body']

      topic_preamble_index, groupbuzz_link = prepare_groupbuzz_link(raw_email_body)
      raw_email_body = raw_email_body[0, topic_preamble_index] if groupbuzz_link
      sender_name = prepare_sender_name(posted_message['sender_name'])
      subject = prepare_subject(posted_message['subject'], sender_name, groupbuzz_link)
      
      body_text = prepare_body_text(raw_email_body)

      message_hash(sender_name, subject, body_text)
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
      remove_embed_removed_marker(text)
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
      # Stripping all new lines because we don't care about it (line formatting) for a preview/snippet.
      body_text = strip_new_lines(text)

      # Remove all embedded images and the header (reply to)/footer(thread)
      body_text = strip_groupbuzz_stuff(body_text)

      body_text = Slack::Notifier::Util::LinkFormatter.format(body_text)

      body_text = convert_to_markdown_bold(body_text)

      body_text = truncate_text(body_text, @truncate_length)

      # TODO - Remove this debug statement
      puts "GroupBuzz::SlackMessagePreparer.prepare_body_text(), body_text\n #{body_text}\n"
      "#{body_text}..."
    end

    def prepare_groupbuzz_link(text)
      topic_preamble_index = text.index(GROUPBUZZ_TOPIC_PREAMBLE) 
      return nil, nil unless topic_preamble_index
      link_start_at = topic_preamble_index + GROUPBUZZ_TOPIC_PREAMBLE.length
      return topic_preamble_index, 
        text[link_start_at, text.length - (link_start_at + GROUPBUZZ_SUBSCRIBE_URL_PART.length)].gsub('http', 'https')      
    end

    # See https://stackoverflow.com/questions/9107658/regex-to-strip-r-and-n-or-r-n
    # Working around issue of double replacement after the first gsub by 
    # replacing the double replacement with what we really want and then doing one more pass
    def strip_new_lines(text)
      text.gsub(/\r?\n/, '<line-break>').gsub(/<line-break><line-break>/, ' ').gsub(/<line-break>/, ' ')
    end

    # See https://stackoverflow.com/questions/8714045/truncate-a-string-without-cut-in-the-middle-of-a-word-in-rails
    def truncate_text(text, length)
      text.match(/^.{0,#{length}}\b/)[0]
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
      }x, MARKER_EMBED_REMOVED
    end

    # Since the hacked-up remove_embedded_images leaves undesired spaces before and after, remove those spaces here
    def remove_embed_removed_marker(text)
      text.gsub(" #{MARKER_EMBED_REMOVED}  ", '')
    end

  end
end