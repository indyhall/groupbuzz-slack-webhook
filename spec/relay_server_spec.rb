require 'spec_helper'

describe RelayServer do
  
  def app
    @app ||= RelayServer
  end
  
  describe "GET '/hello-world'" do
    it "should be successful" do
      get '/hello-world'
      expect(last_response).to be_ok
    end
  end
  
end
