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
    mw.call(mock_env)
  end

  def mock_env
    Rack::MockRequest.env_for('/')
  end
end
