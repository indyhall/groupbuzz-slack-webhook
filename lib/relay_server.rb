require 'bundler' ; Bundler.require
require 'json'
require "sinatra/base"
require 'slack-notifier'
require 'pry'
require 'facets/hash/symbolize_keys'
require 'facets/yaml'

class RelayServer < Sinatra::Base

  configure do
    GroupBuzz::SettingsHolder.settings = YAML::load_file(File.join(__dir__, '../config/settings.yml')).symbolize_keys.clone
  end


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
    @slack_poster ||= GroupBuzz::SlackPoster.new
  end

end