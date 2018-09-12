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
      raise "Error! GROUPBUZZ_RELAY_SLACK_WEBHOOK not set as environment variable!" unless ENV['GROUPBUZZ_RELAY_SLACK_WEBHOOK']
      raise "Error! GROUPBUZZ_RELAY_SLACK_CHANNEL not set as environment variable!" unless ENV['GROUPBUZZ_RELAY_SLACK_CHANNEL']
      raise "Error! GROUPBUZZ_RELAY_SLACK_USERNAME not set as environment variable!" unless ENV['GROUPBUZZ_RELAY_SLACK_USERNAME']

      @slack_notifier ||= Slack::Notifier.new ENV['GROUPBUZZ_RELAY_SLACK_WEBHOOK'] do
        defaults channel: ENV['GROUPBUZZ_RELAY_SLACK_CHANNEL'],
                 username: ENV['GROUPBUZZ_RELAY_SLACK_USERNAME']
      end
    end

  end
end