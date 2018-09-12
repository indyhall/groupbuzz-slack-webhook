require 'spec_helper'

describe GroupBuzz::SlackMessagePreparer do
    
  DEFAULT_SUBJECT = 'This is a subject'
  DEFAULT_SENDER_NAME = "\"Jane Doe\" via GroupBuzz"
  DEFAULT_EMAIL_BODY = 'This is the email body.'
  DEFAULT_TRUNCATE_LENGTH = 249
  DEFAULT_TRUNCATE_LINES = 3

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

    it 'should strip out the GB message header' do
      original = "#{GroupBuzz::SlackMessagePreparer::GROUPBUZZ_REPLY_HEADER_LINE}\nThis is the first real sentence."
      check_email_body(prepare_with_email_body(email_body: original), 
        "\nThis is the first real sentence.")      
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

  context "subject" do
  end

  context "GB footer removal with link extraction" do
  end

  context "Disregard digest emails" do
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
        "#{original[0, DEFAULT_TRUNCATE_LENGTH]}…")      
    end

  end

  def prepare_with_email_body(email_body: email_body, 
    strip_new_lines: strip_new_lines = false,
    truncate_lines: truncate_lines = DEFAULT_TRUNCATE_LINES,
    truncate_length: truncate_length = DEFAULT_TRUNCATE_LENGTH)
    postable, slack_message = prepare_with_email_body_direct(email_body, strip_new_lines, truncate_lines, truncate_length)
    slack_message
  end

  def prepare_with_email_body_direct(email_body, strip_new_lines, truncate_lines, truncate_length)
    message_preparer(strip_new_lines: strip_new_lines, truncate_length: truncate_length, truncate_lines: truncate_lines)
      .prepare(test_message(email_body: email_body))
  end

  def check_email_body(slack_message, expected)
    expect(slack_message[:attachments].first[:text]).to eq(expected)
  end

  def test_message(email_body: email_body = DEFAULT_EMAIL_BODY,
    sender_name: sender_name = DEFAULT_SENDER_NAME,
    subject: subject = DEFAULT_SUBJECT)
    {'email_body' => email_body,
     'sender_name' => sender_name,
     'subject' => subject
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
    strip_new_lines: strip_new_lines,
    truncate_length: truncate_length,
    truncate_lines: truncate_lines)
    message_preparer = GroupBuzz::SlackMessagePreparer.new
    message_preparer.strip_new_lines = strip_new_lines
    message_preparer.truncate_length = truncate_length
    message_preparer.truncate_lines = truncate_lines
    message_preparer
  end

end
