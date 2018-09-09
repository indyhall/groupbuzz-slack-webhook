require 'bundler' ; Bundler.require
require 'json'
require "sinatra/base"
require "sinatra/config_file"
require 'slack-notifier'

class RelayServer < Sinatra::Base
  register Sinatra::ConfigFile

  config_file 'config/settings.yml'  

  get '/hello-world' do
    "Hello World!"
  end

  post '/post-to-slack' do
  end

  post '/slack-conversion-tester' do
  end

  private

  def slack_notifier
    @slack_notifier ||= Slack::Notifier.new settings.slack_webhook do
      defaults channel: settings.slack_channel,
               username: settings.slack_username
    end
  end

end