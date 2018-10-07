require 'spec_helper'
require_relative 'support/data_helper'

describe GroupBuzz::SlackMessagePreparer do

  RSpec.configure do |c|
    c.include DataHelper
  end

  context "formatting of email body" do

    it "should pass through _italics formatting_" do
      original = 'This is _italic formatted_. This is _italicized_!'      
      check_email_body(prepare_with_email_body(email_body: original), original)
    end

    it "should convert **double bold formatting** to single bold, preserve existing *single bold formatting* and ignore lone asterisks" do
      original = 'This is **strong bold formatted** This is a lone asterisk * just, another one couple * * out there *bold*'      
      check_email_body(prepare_with_email_body(email_body: original), 
        'This is *strong bold formatted* This is a lone asterisk * just, another one couple * * out there *bold*')
    end

    it "should not do anything with GB-style quotes" do
      original = '> To judge you by your failures is to cast blame upon the seasons for their inconstancy.\n-Kahlil Gibran, The Prophet'
      check_email_body(prepare_with_email_body(email_body: original), original)
    end

    it "should remove all embedded uploads.groupbuzz.io image links" do
      original = "BeforeTheEmbed![giphy__281_29.gif](//s3.amazonaws.com/uploads.groupbuzz.io/production/uploads/3473/original/c5e8a744fe873dcfb4d70a7770db52f50f9b2348.gif?1526503036 'giphy__281_29.gif')AfterTheEmbed"
      check_email_body(prepare_with_email_body(email_body: original), 'BeforeTheEmbedAfterTheEmbed')
    end

    it 'should convert all Markdown-style hyperlinks to Slack\'s expected format' do
      original = "BeforeTheHyperlink[Jane Doe Shindigs](https://www.janedoe.com/)AfterTheHyperlink"
      check_email_body(prepare_with_email_body(email_body: original), 
        "BeforeTheHyperlink<https://www.janedoe.com/|Jane Doe Shindigs>AfterTheHyperlink")
    end

    it 'should strip out the GB message header and all newline characters prior to first sentence' do
      original = "#{GroupBuzz::SlackMessagePreparer::GROUPBUZZ_REPLY_HEADER_LINE}\r\n\r\nThis is the first real sentence."
      check_email_body(prepare_with_email_body(email_body: original), 
        "This is the first real sentence.")      
    end

    it 'should not strip new lines over truncate limit unless enabled' do
      check_email_body(prepare_with_email_body(email_body: new_lines_sample, 
        truncate_length: new_lines_sample.length + 1, truncate_lines: 9), 
        new_lines_sample)
    end

    it 'should strip new lines and replace new line \r\n character series with single space when enabled' do
      original = "This is line one.\r\nThis is line two.\r\n\r\nThis is line three.\r\n\r\n\r\nThis is line four.\r\n\r\n\r\n\r\n"
      check_email_body(prepare_with_email_body(strip_new_lines: true, email_body: original), 
        "This is line one. This is line two. This is line three. This is line four. ")
    end

    it 'should return empty if given empty' do
      original = ''     
      check_email_body(prepare_with_email_body(email_body: original), original)
    end

  end

  context "sender" do

    it "should extract the sender if GB formatted" do
      check_email_author_name(prepare_with_email_body(email_sender_name: "\"Jane Doe\" via GroupBuzz"),
        "Jane Doe")
    end

    it "should use a plain sender if there was no GB formatted sender name" do
      original_sender_name = "Plain Jane Doe"
      check_email_author_name(prepare_with_email_body(email_sender_name: original_sender_name),
        original_sender_name)
    end

  end

  context "subject" do

    it 'should extract the GB topic link from the email body footer' do
      topic_link = "http://indyhall.groupbuzz.io/topics/16997-next-week-is-member-photo-week/"
      topic_subscribe_link = "#{topic_link}subscribe"
      original_body = "\r\n\r\n\r\n#{GroupBuzz::SlackMessagePreparer::GROUPBUZZ_TOPIC_PREAMBLE}#{topic_subscribe_link}"
      original_subject = "This is a new subject"
      check_email_pretext(prepare_with_email_body(email_body: original_body, email_subject: original_subject),
        "<#{topic_link.gsub('http','https')}|#{original_subject}>")
    end

    it 'should use a plain subject if there was no proper GB email body footer' do
      original_body = "\r\n\r\n\r\nThis is a sentence."
      original_subject = "This is a new subject"
      check_email_pretext(prepare_with_email_body(email_body: original_body, email_subject: original_subject),
        original_subject)
    end

  end

  context "Disregard digest emails" do

    it 'should reject digest-type emails based on subject' do
      original_subject = "#{GroupBuzz::SettingsHolder.settings[:message_subject_prefix]} This is a subject that has the magic reject phrase #{GroupBuzz::SlackMessagePreparer::GROUPBUZZ_DISCUSSION_FROM_SUBJECT}"
      posted, message = prepare_with_email_body_direct(email_subject: original_subject)
      expect(posted).to be_false
    end

    it 'should reject digest-type emails on email body' do
      original_body = "This is content that has the magic reject phrase #{GroupBuzz::SlackMessagePreparer::GROUPBUZZ_RECENT_DISCUSSIONS_HEADER}"
      posted, message = prepare_with_email_body_direct(email_body: original_body)
      expect(posted).to be_false
    end

  end

  # Distinct lines are any lines with one or more line breaks (\r\n)
  # Preserving more than one line break (blank lines in between text) is currently not handled.
  context "truncation" do

    it 'should not truncate if text length is shorter than truncate length' do
      original = 'This should not be truncated.'
      check_email_body(prepare_with_email_body(email_body: original), original)
    end

    it 'should truncate based on max distinct lines if under truncate length' do
      original = "This is line one.\r\n\r\nThis is line two.\r\n.This is line three.\r\nThis is line four."
      check_email_body(prepare_with_email_body(email_body: original),
        "This is line one.\r\nThis is line two.\r\n.This is line three.")
    end

    it 'should truncate based on length if max distinct lines is not exceeded' do
      original = long_text_sample
      check_email_body(prepare_with_email_body(email_body: original),
        "#{original[0, DataHelper::DEFAULT_TRUNCATE_LENGTH+1]}…")      
    end

    # This will produce the following error if final regexp was still using /s and not /i
    # Encoding::CompatibilityError:
    #   incompatible encoding regexp match (Windows-31J regexp with UTF-8 string)
    it 'should foo' do
      original = ("Ĳ" * DataHelper::DEFAULT_TRUNCATE_LENGTH).force_encoding('utf-8')
      check_email_body(prepare_with_email_body(email_body: original),
        "#{original[0, DataHelper::DEFAULT_TRUNCATE_LENGTH+1]}…")
    end

    # punting on this... too difficult
    xit 'should optimally linebreak on multi-line, blank spaced' do
      original = "Please REPLY ABOVE THIS LINE to respond by email.\r\n\r\nWondering how to get your face on the tv screens around Indy Hall? Or do you see your pic and think \"oh jeez, that's so old!\"\r\n\r\nI'm here to help!\r\n\r\n**All next week** I'll have my camera around Indy Hall, ready to snap your member photo! It'll be quick, easy, and (believe it or not) you might have fun! I'll be inviting folks who don't have pics yet to get one, but if you would like a new photo, don't hesitate to ask- I'm happy to update yours!\r\n\r\nPluuuus if you like I'll send you your photo to use for linkedin, facebook, whatever (just credit me at [Sam Abrams Photography](https://www.samabramsphotography.com/) ;) )\r\n\r\nI'll see you next week- come see me whenever you're feeling photogenic!\r\n\r\n\r\n![giphy__281_29.gif](//s3.amazonaws.com/uploads.groupbuzz.io/production/uploads/3473/original/c5e8a744fe873dcfb4d70a7770db52f50f9b2348.gif?1526503036 'giphy__281_29.gif')\r\n\r\n\r\nFollow this topic if you would like to be notified of new posts in this discussion: http://indyhall.groupbuzz.io/topics/16997-next-week-is-member-photo-week/subscribe"
      check_email_body(prepare_with_email_body(email_body: original),
        'TBD')  
    end

  end

  def prepare_with_email_body(
    email_body: email_body = DataHelper::DEFAULT_EMAIL_BODY, 
    email_subject: email_subject = DataHelper::DEFAULT_SUBJECT,
    email_sender_name: email_sender_name = DataHelper::DEFAULT_SENDER_NAME,
    strip_new_lines: strip_new_lines = false,
    truncate_lines: truncate_lines = DataHelper::DEFAULT_TRUNCATE_LINES,
    truncate_length: truncate_length = DataHelper::DEFAULT_TRUNCATE_LENGTH)
    
    postable, slack_message = prepare_with_email_body_direct(
      email_body: email_body, email_subject: email_subject, email_sender_name: email_sender_name,
      strip_new_lines: strip_new_lines, truncate_lines: truncate_lines, truncate_length: truncate_length)
    slack_message
  end

  def prepare_with_email_body_direct(
    email_subject: email_subject = DataHelper::DEFAULT_SUBJECT,
    email_body: email_body = DataHelper::DEFAULT_EMAIL_BODY, 
    email_sender_name: email_sender_name = DataHelper::DEFAULT_SENDER_NAME,
    strip_new_lines: strip_new_lines = DataHelper::DEFAULT_STRIP_NEW_LINES, 
    truncate_lines: truncate_lines = DataHelper::DEFAULT_TRUNCATE_LINES, 
    truncate_length: truncate_length = DataHelper::DEFAULT_TRUNCATE_LENGTH)

    message_preparer(strip_new_lines: strip_new_lines, truncate_length: truncate_length, truncate_lines: truncate_lines)
      .prepare(test_message(email_subject: email_subject, email_body: email_body, email_sender_name: email_sender_name))
  end

  def check_email_author_name(slack_message, expected)
    check_email_contents(slack_message, :author_name, expected)
  end

  def check_email_pretext(slack_message, expected)
    check_email_contents(slack_message, :pretext, expected)
  end

  def check_email_body(slack_message, expected)
    check_email_contents(slack_message, :text, expected)
  end

  def check_email_contents(slack_message, key, expected)
    expect(slack_message[:attachments].first[key]).to eq(expected)
  end

  def test_message(email_body: email_body = DataHelper::DEFAULT_EMAIL_BODY,
    email_sender_name: email_sender_name = DataHelper::DEFAULT_SENDER_NAME,
    email_subject: subject)
    {'email_body' => email_body,
     'sender_name' => email_sender_name,
     'subject' => email_subject
    }
  end

  def new_lines_sample
    a_ditty =
      "Do, a deer, a female deer.\r\n"/
      "Re, a drop of golden sun.\r\n"/
      "Me, a name I call myself.\r\n"/
      "Fa, a long long way to run.\r\n"/
      "So, a needle pulling thread.\r\n"/
      "La, a note to follow so.\r\n"/
      "Ti, a drink with jam and bread.\r\n"/
      "That will bring us back to do, oh, oh, oh…\r\n"
    a_ditty
  end

  def long_text_sample
    "The really important kind of freedom involves attention and awareness and discipline, and being able truly to care about other people and to sacrifice for them over and over in myriad petty, unsexy ways every day. That is real freedom. That is being educated, and understanding how to think. The alternative is unconsciousness, the default setting, the rat race, the constant gnawing sense of having had, and lost, some infinite thing."
  end    

  def message_preparer(
    strip_new_lines: strip_new_lines = true,
    truncate_length: truncate_length = DataHelper::DEFAULT_TRUNCATE_LENGTH,
    truncate_lines: truncate_lines = DataHelper::DEFAULT_TRUNCATE_LINES)
    ENV['GROUPBUZZ_RELAY_SLACK_MESSAGE_SUBJECT_PREFIX'] = DataHelper::DEFAULT_MESSAGE_SUBJECT_PREFIX
    message_preparer = GroupBuzz::SlackMessagePreparer.new

    message_preparer.original_message_debug_logging = false
    message_preparer.strip_new_lines = strip_new_lines
    message_preparer.truncate_length = truncate_length
    message_preparer.truncate_lines = truncate_lines
    message_preparer
  end

end
