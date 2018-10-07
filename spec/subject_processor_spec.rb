require 'spec_helper'
require_relative 'support/data_helper'

describe GroupBuzz::SubjectProcessor do

  RSpec.configure do |c|
    c.include DataHelper
  end
  
  context "format subject" do

    it 'should format the subject as a Slack link with the link converted to https' do
      gb_topic_link = "http://indyhall.groupbuzz.io/topics/16997-next-week-is-member-photo-week/"
      expected_subject = formatted_subject_link(gb_topic_link.gsub('http','https'), DataHelper::DEFAULT_SUBJECT)
      check_subject_format(DataHelper::DEFAULT_SUBJECT, gb_topic_link, expected_subject)
    end

    it 'should format the subject as a Slack link with the link' do
      gb_topic_link = "https://indyhall.groupbuzz.io/topics/16997-next-week-is-member-photo-week/"
      expected_subject = formatted_subject_link(gb_topic_link, DataHelper::DEFAULT_SUBJECT)
      check_subject_format(DataHelper::DEFAULT_SUBJECT, gb_topic_link, expected_subject)
    end

    it 'should not format the subject as a Slack link if there is no link' do
      check_subject_format(DataHelper::DEFAULT_SUBJECT, nil, DataHelper::DEFAULT_SUBJECT)
    end

  end

  def check_subject_format(subject, groupbuzz_link, expected_subject)
    formatted_subject = subject_processor.format_subject(subject, groupbuzz_link)
    expect(formatted_subject).to eq(expected_subject)
  end

  def formatted_subject_link(topic_link, original_subject)
    "<#{topic_link}|#{original_subject}>"
  end

  def subject_processor
    @subject_processor ||= GroupBuzz::SubjectProcessor.new(DataHelper::DEFAULT_MESSAGE_SUBJECT_PREFIX)
  end

end
