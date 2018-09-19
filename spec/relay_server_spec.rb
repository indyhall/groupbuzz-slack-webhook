require 'spec_helper'

describe RelayServer do
  
  def app
    @app ||= RelayServer
  end
  
  describe "RelayServer" do

    it "should be successful for ping url" do
      get '/hello-world'
      expect(last_response).to be_ok
    end

    it "should fail on empty message post" do
      post '/post-to-slack'
      expect(last_response).to_not be_ok
    end

  end
  
end
