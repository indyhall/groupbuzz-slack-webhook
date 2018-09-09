require 'bundler' ; Bundler.require
require 'json'
require "sinatra/base"
require "sinatra/config_file"
require 'slack-notifier'
require 'pry'

class RelayServer < Sinatra::Base
  register Sinatra::ConfigFile

  # TODO move config file to something that is initialized from YAML at startup
  config_file '../config/settings.yml'  

  get '/hello-world' do
    "Hello World!"
  end

  post '/post-to-slack' do
    message_post = JSON.parse(request.body.read)
    slack_poster.post(message_post)
    {'sent_status' => 'ok'}.to_json
  end

  post '/slack-conversion-tester' do
  end

  private

  def strip_header_line(text)
  end

  def slack_poster
    @slack_poster ||= GroupBuzz::SlackPoster.new(slack_webhook: settings.slack_webhook, slack_channel: settings.slack_channel, 
      slack_username: settings.slack_username, message_truncate_length: settings.message_truncate_length,
      message_subject_prefix: settings.message_subject_prefix)
  end

end