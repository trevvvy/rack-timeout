module MiddlewareHelper
  def app(&block)
    lambda do |_env|
      block.call unless block.nil?
      [200, { 'Content-Type' => 'text/plain' }, ['hello']]
    end
  end

  def run_middleware_with_timeout(timeout_time = 0.1, &block)
    mw = Rack::Timeout.new(app(&block))
    Rack::Timeout.timeout = timeout_time
    Rack::Timeout.explain = timeout_time / 2
    Rack::Timeout.include_gems = false
    mw.call(mock_env)
  end

  def run_middleware_with_timeout_and_gems(timeout_time = 0.1, &block)
    mw = Rack::Timeout.new(app(&block))
    Rack::Timeout.timeout = timeout_time
    Rack::Timeout.explain = timeout_time / 2
    Rack::Timeout.include_gems = true
    mw.call(mock_env)
  end
  
  def run_middleware_with_timeout_and_stack_depth(timeout_time = 0.1, stack_depth = 5, &block)
    mw = Rack::Timeout.new(app(&block))
    Rack::Timeout.timeout = timeout_time
    Rack::Timeout.explain = timeout_time / 2
    Rack::Timeout.stack_depth = stack_depth
    mw.call(mock_env)
  end

  def mock_env
    Rack::MockRequest.env_for('/')
  end
end
