class InboundRequestsLoggerMiddleware
  attr_accessor :only_state_change, :path_regexp

  def initialize(app, only_state_change: true, path_regexp: /.*/)
    @app = app
    self.only_state_change = only_state_change
    self.path_regexp = path_regexp
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    logging = log?(env, request)
    if logging
      env["INBOUND_REQUEST_LOG"] = InboundRequestLog.from_request(request)
      request.body.rewind
    end
    status, headers, body = @app.call(env)
    if logging
      env["INBOUND_REQUEST_LOG"].update_columns(response_body: parsed_body(body),
                                                response_code: status,
                                                ended_at: Time.current,
                                                ip_used: request.remote_ip)
    end
    [status, headers, body]
  end

  private

  def log?(env, request)
    env["PATH_INFO"] =~ path_regexp && (!only_state_change || request_with_state_change?(request))
  end

  def parsed_body(body)
    return unless body.present?

    if body.respond_to?(:body)
      JSON.parse(body.body)
    elsif body.respond_to?(:[])
      JSON.parse(body[0])
    else
      body
    end
  rescue JSON::ParserError
    body
  end

  def request_with_state_change?(request)
    request.post? || request.put? || request.patch? || request.delete?
  end
end
