module RailsApiLogger
  class Middleware
    attr_accessor :only_state_change, :host_regexp, :path_regexp, :skip_request_body_regexp, :skip_response_body_regexp

    def initialize(app, only_state_change: true,
      host_regexp: /.*/,
      path_regexp: /.*/,
      skip_request_body_regexp: nil,
      skip_response_body_regexp: nil)
      @app = app
      self.only_state_change = only_state_change
      self.host_regexp = host_regexp
      self.path_regexp = path_regexp
      self.skip_request_body_regexp = skip_request_body_regexp
      self.skip_response_body_regexp = skip_response_body_regexp
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      logging = log?(env, request)
      if logging
        env["INBOUND_REQUEST_LOG"] = InboundRequestLog.from_request(request, skip_request_body: skip_request_body?(env))
        request.body.rewind if request.body.respond_to?(:rewind)
      end
      status, headers, body = @app.call(env)
      if logging
        updates = {response_code: status, ended_at: Time.current}
        updates[:response_body] = if skip_response_body?(env)
          "[Skipped]"
        else
          parsed_body(body)
        end
        # this usually works. let's be optimistic.
        begin
          env["INBOUND_REQUEST_LOG"].update_columns(updates)
        rescue JSON::GeneratorError => _e # this can be raised by activerecord if the string is not UTF-8.
          env["INBOUND_REQUEST_LOG"].update_columns(updates.except(:response_body))
        end
      end
      [status, headers, body]
    end

    private

    def skip_request_body?(env)
      skip_request_body_regexp && env["PATH_INFO"] =~ skip_request_body_regexp
    end

    def skip_response_body?(env)
      skip_response_body_regexp && env["PATH_INFO"] =~ skip_response_body_regexp
    end

    def log?(env, request)
      # The HTTP_HOST header is preferred to the SERVER_NAME header per the Rack spec: https://github.com/rack/rack/blob/main/SPEC.rdoc#label-The+Environment
      host = env["HTTP_HOST"] || env["SERVER_NAME"]
      path = env["PATH_INFO"]
      (host =~ host_regexp) &&
        (path =~ path_regexp) &&
        (!only_state_change || request_with_state_change?(request))
    end

    def parsed_body(body)
      return unless body.present?
      parsable_body = if body.respond_to?(:to_ary)
        body.to_ary[0]
      elsif body.respond_to?(:body)
        body.body
      else
        body
      end

      JSON.parse(parsable_body)
    rescue JSON::ParserError, ArgumentError
      parsable_body
    end

    def request_with_state_change?(request)
      request.post? || request.put? || request.patch? || request.delete?
    end
  end
end
