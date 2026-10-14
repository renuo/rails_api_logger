module RailsApiLogger
  class Logger
    def initialize(loggable = nil, client_reference: nil, skip_request_body: false, skip_response_body: false)
      @loggable = loggable
      @client_reference = client_reference
      @skip_request_body = skip_request_body
      @skip_response_body = skip_response_body
    end

    def call(url, request)
      log = OutboundRequestLog.from_request(request, loggable: @loggable, client_reference: @client_reference,
        skip_request_body: @skip_request_body)
      yield.tap do |response|
        log.from_response(response, skip_response_body: @skip_response_body)
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
