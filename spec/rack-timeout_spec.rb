require 'spec_helper'

class RackTimeoutStatus < StandardError; end

describe Rack::Timeout do
  before :each do
    # shut up the logger
    Rack::Timeout.logger.level = ::Logger::FATAL
  end

  def app(sleep_time = 0)
    lambda do |_env|
      sleep sleep_time
      [200, { 'Content-Type' => 'text/plain' }, ['hello']]
    end
  end

  def middleware(timeout_time = 1, sleep_time = 0)
    mw = Rack::Timeout.new(app(sleep_time))
    Rack::Timeout.timeout = timeout_time

    mw
  end

  def mock_env
    Rack::MockRequest.env_for('/')
  end

  describe 'killing requests' do
    it 'kills a request that runs past the timeout' do
      expect { middleware(0.1, 0.2).call(mock_env) }.to raise_error(Rack::Timeout::RequestTimeoutError)
    end
  end

  describe 'notifications' do
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

    it 'notifies every second when a request is processing' do
      middleware(5, 2.1).call(mock_env)
      expect(@notifications.find { |e| e.state == :active && e.duration.to_i == 1 }).to be_true
      expect(@notifications.find { |e| e.state == :active && e.duration.to_i == 2 }).to be_true
    end

    it 'notifies that a timed out request has been killed' do
      middleware(0.1, 0.2).call(mock_env) rescue nil
      expect(@notifications.find { |e| e.state == :timed_out }).to be_true
    end
  end

end
