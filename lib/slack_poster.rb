require 'pry'

module GroupBuzz
  class SlackPoster

    # TODO - Get a real way to load from the YAML without passing
    def initialize(slack_webhook: slack_webhook, 
      slack_channel: slack_channel,  
      slack_username: slack_username, 
      message_truncate_length: message_truncate_length,
      message_subject_prefix: message_subject_prefix)
      @slack_webhook = slack_webhook
      @slack_channel = slack_channel
      @slack_username = slack_username
      @message_truncate_length = message_truncate_length
      @message_subject_prefix = message_subject_prefix
    end

    def post(message_post)
      message = GroupBuzz::SlackMessagePreparer.new(@message_truncate_length, @message_subject_prefix).prepare(message_post)
      slack_notifier.ping message
    end
    
    private

    def slack_notifier
      @slack_notifier ||= Slack::Notifier.new @slack_webhook do
        defaults channel: @slack_channel,
                 username: @slack_username
      end
    end

  end
end