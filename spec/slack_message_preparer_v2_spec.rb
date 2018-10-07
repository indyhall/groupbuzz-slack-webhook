require 'spec_helper'
require_relative 'support/data_helper'

describe GroupBuzz::SlackMessagePreparerV2 do

  RSpec.configure do |c|
    c.include DataHelper
  end

  context "test messages" do
  
    it "simple case - WIP until truncate processor complete" do
      status, message = message_preparer.prepare(test_message(email_body: 'foobar', email_subject: 'foobar subject'))
    end

  end

  def message_preparer
    ENV['GROUPBUZZ_RELAY_SLACK_MESSAGE_SUBJECT_PREFIX'] = DataHelper::DEFAULT_MESSAGE_SUBJECT_PREFIX
    GroupBuzz::SettingsHolder.settings[:original_message_debug_logging] = false
    GroupBuzz::SlackMessagePreparerV2.new
  end

  def test_message(email_body: email_body = DataHelper::DEFAULT_EMAIL_BODY,
    email_sender_name: email_sender_name = DataHelper::DEFAULT_SENDER_NAME,
    email_subject: subject)
    {'email_body' => email_body,
     'sender_name' => email_sender_name,
     'subject' => email_subject
    }
  end

end