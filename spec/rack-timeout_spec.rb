require 'spec_helper'

class RackTimeoutStatus < StandardError; end

describe Rack::Timeout do

  let(:app) { ->(_env) { sleep 1; [200, { 'Content-Type' => 'text/plain' }, ['hello']] } }
  let(:mock_env) { Rack::MockRequest.env_for('/') }
  let(:middleware) { Rack::Timeout.new(app) }

  describe 'events' do
    before :each do
      @notifications = []
      Rack::Timeout.register_state_change_observer(:test_observer) do |env| 
        @notifications << env["rack-timeout.info"].dup
      end
    end

    after :each do
      Rack::Timeout.unregister_state_change_observer(:test_observer)
    end

    it 'notifies at the start of a request' do
      middleware.call(mock_env)
      expect(@notifications.first.state).to eq(:ready)
    end

    it 'notifies when a request is complete' do
      middleware.call(mock_env)
      expect(@notifications.last.state).to eq(:completed)
    end
  end

end
