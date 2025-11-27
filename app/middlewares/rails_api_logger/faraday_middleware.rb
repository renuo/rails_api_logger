module RailsApiLogger
  class FaradayMiddleware < Faraday::Middleware
    def initialize(app, options = {})
      super(app)
      @options = options
    end

    def call(env)
      log = OutboundRequestLog.from_request(env, loggable: @options[:loggable], skip_request_body: @options[:skip_request_body])

      @app.call(env).on_complete do |response_env|
        log.from_response(response_env.response, skip_response_body: @options[:skip_response_body])
      end
    rescue => e
      log.response_body = {error: e.message} if log
      raise
    ensure
      log.ended_at = Time.current
      log.save!
    end
  end
end
