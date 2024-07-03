class InboundRequestsLoggerMiddleware
  attr_accessor :only_state_change, :path_regexp, :skip_body_regexp, :keep_headers, :subdomain_regexp

  DEFAULT_HEADERS = %w[HTTP_USER_AGENT HTTP_REFERER HTTP_ACCEPT HTTP_ACCEPT_LANGUAGE HTTP_ACCEPT_ENCODING].freeze

  def initialize(app, only_state_change: true, path_regexp: /.*/, skip_body_regexp: nil, keep_headers: DEFAULT_HEADERS, subdomain_regexp:  /.*/)
    @app = app
    self.only_state_change = only_state_change
    self.path_regexp = path_regexp
    self.skip_body_regexp = skip_body_regexp
    self.keep_headers = keep_headers
    self.subdomain_regexp = subdomain_regexp
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    logging = log?(env, request)
    if logging
      env["INBOUND_REQUEST_LOG"] = InboundRequestLog.from_request(request, keep_headers: keep_headers)
      request.body&.rewind
    end
    status, headers, body = @app.call(env)
    if logging
      updates = {
        response_code: status,
        ended_at: Time.current,
      }
      if request.respond_to?(:remote_ip) && request.remote_ip.present?
        updates[:ip_used] = request.remote_ip
      end
      updates[:response_body] = parsed_body(body) if log_response_body?(env)
      env["INBOUND_REQUEST_LOG"].update!(updates)
      if !headers["action_dispatch.request_id"]
        headers.merge!({ 'Request-Id' => env["INBOUND_REQUEST_LOG"].uuid })
      end
    end
    [status, headers, body]
  end

  private

  def log_response_body?(env)
    skip_body_regexp.nil? || env["PATH_INFO"] !~ skip_body_regexp
  end

  def log?(env, request)
    (env["PATH_INFO"] =~ path_regexp || request.subdomain =~ subdomain_regexp) && (!only_state_change || request_with_state_change?(request))
  end

  def to_utf8(body)
    body&.force_encoding('UTF-8')&.encode('UTF-8', invalid: :replace)
  end

  def parsed_body(body)
    return unless body.present?

    if body.respond_to?(:body) && body.body.empty?
      nil
    elsif body.respond_to?(:body)
      JSON.parse(to_utf8(body.body))
    elsif body.respond_to?(:[])
      JSON.parse(to_utf8(body[0]))
    else
      to_utf8(body)
    end
  rescue JSON::ParserError, ArgumentError
    if body.instance_of?(String)
      to_utf8(body)
    else
      body
    end
  end

  def request_with_state_change?(request)
    request.post? || request.put? || request.patch? || request.delete?
  end
end
