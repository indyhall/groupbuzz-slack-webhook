require 'pry'

module GroupBuzz
  class SlackPoster

    def initialize
      @slack_webhook = GroupBuzz::SettingsHolder.settings[:slack_webhook]
      @slack_channel = GroupBuzz::SettingsHolder.settings[:slack_channel]
      @slack_username = GroupBuzz::SettingsHolder.settings[:slack_username]
    end

    def post(message_post)
      postable, message = GroupBuzz::SlackMessagePreparer.new.prepare(message_post)
      slack_notifier.ping message if postable
      return postable
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