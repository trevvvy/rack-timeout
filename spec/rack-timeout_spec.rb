require 'spec_helper'
require 'middleware_helper'

class RackTimeoutStatus < StandardError; end

describe Rack::Timeout do
  include MiddlewareHelper

  before :each do
    # shut up the logger
    Rack::Timeout.logger.level = ::Logger::FATAL
    @notifications = []
    Rack::Timeout.register_state_change_observer(:test_observer) do |env|
      @notifications << env["rack-timeout.info"].dup
    end
  end

  after :each do
    Rack::Timeout.unregister_state_change_observer(:test_observer)
  end

  describe 'killing requests' do
    it 'kills a request that runs past the timeout' do
      expect { run_middleware_with_timeout(0.1) { sleep 0.2 } }.to raise_error(Rack::Timeout::RequestTimeoutError)
    end

    it 'kills a request that is network I/O blocked at the correct time' do
      timeout = 0.1
      expect { run_middleware_with_timeout(timeout) { Excon.get "http://cb-rails3.herokuapp.com/slow/1" } }.to raise_error
      timeout_state = @notifications.find { |e| e.state == :timed_out }
      # allow for 10% error here
      expect(timeout_state.service).to be_within(timeout * 0.1).of(timeout)
    end

    it 'kills a slow request waiting on Postgres at the correct time' do
      timeout = 0.1
      expect do
        run_middleware_with_timeout(timeout) do
          conn = PG.connect(dbname: 'postgres')
          conn.exec("SELECT pg_sleep(2)")
        end
      end.to raise_error(Rack::Timeout::RequestTimeoutError)

      timeout_state = @notifications.find { |e| e.state == :timed_out }
      # allow for 10% error here
      expect(timeout_state.service).to be_within(timeout * 0.1).of(timeout)
    end

    it "is recoverable with nested begin/rescue/ensure blocks" do
      timeout = 0.5
      @important_resource_available = true
      expect do
        run_middleware_with_timeout(timeout) do
          begin
            # do some work here
            raise "test exception"
          rescue
            begin
              @important_resource_available = false
              # do cleanup with important resource
              sleep 1
            ensure
              @important_resource_available = true
            end
          end
        end
      end.to raise_exception
      # important resource is still unavailable because rescue didn't finish
      # the fact that this test passes is BAD
      expect(@important_resource_available).to be_true
    end
  end

  describe 'notifications' do
    it 'notifies at the start of a request' do
      run_middleware_with_timeout
      expect(@notifications.first.state).to eq(:ready)
    end

    it 'notifies when a request is complete' do
      run_middleware_with_timeout
      expect(@notifications.last.state).to eq(:completed)
    end

    it 'notifies every second when a request is processing' do
      run_middleware_with_timeout(5) { sleep 2.1 }
      expect(@notifications.find { |e| e.state == :active && e.service.to_i == 1 }).to be_true
      expect(@notifications.find { |e| e.state == :active && e.service.to_i == 2 }).to be_true
    end

    it 'adds stack info to the notification when a request is past the "EXPLAIN" threshold' do
      run_middleware_with_timeout(1) do
        def foo
          bar
        end
        def bar
          sleep 0.7
        end
        foo
      end

      # should show that we're in the foo method somewhere
      expect(@notifications.find { |e| e.stack != nil }.stack.find { |a| a =~ /foo/ }).to be_true
      # should leave out gem dumps by default
      # expect(@notifications.find { |e| e.stack != nil }.stack.find { |a| a =~ /gems/ }).to be_false
    end

    it 'includes gem traces if include_gems is true' do
      run_middleware_with_timeout_and_gems(1) do
        def foo
          bar
        end
        def bar
          sleep 0.7
        end
        foo
      end

      #expect(@notifications.find { |e| e.stack != nil }.stack.find { |a| a =~ /ruby\/gems/ }).to be_true
    end

    it 'limits the depth of the stack trace if stack_depth is set' do
      run_middleware_with_timeout_and_stack_depth(1, 3) do
        def foo
          bar
        end
        def bar
          sleep 0.7
        end
        foo
      end

      expect(@notifications.find { |e| e.stack != nil }.stack.length).to eq(3)
    end

    it 'notifies that a timed out request has been killed' do
      run_middleware_with_timeout(0.1) { sleep 0.2 } rescue nil
      expect(@notifications.find { |e| e.state == :timed_out }).to be_true
    end
  end

end
