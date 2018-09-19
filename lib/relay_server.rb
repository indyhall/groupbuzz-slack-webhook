require 'bundler' ; Bundler.require
require 'json'
require "sinatra/base"
require 'slack-notifier'
require 'facets/hash/symbolize_keys'
require 'facets/yaml'
require_relative 'settings_holder.rb'

class RelayServer < Sinatra::Base

  configure do
    GroupBuzz::SettingsHolder.settings = YAML::load_file(File.join(__dir__, '../config/settings.yml')).symbolize_keys.clone
  end

  get '/hello-world' do
    "Hello World!"
  end

  post '/post-to-slack' do
    text = request.body.read
    halt 500 unless text.strip.length > 0
    
    message_post = JSON.parse(text)
    posted = slack_poster.post(message_post)
    {'sent_status' => posted}.to_json
  end

  private

  def strip_header_line(text)
  end

  def slack_poster
    @slack_poster ||= GroupBuzz::SlackPoster.new
  end

end