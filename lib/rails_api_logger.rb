require "active_record"
require "nokogiri"
require "rails_api_logger/version"
require "rails_api_logger/request_log"
require "rails_api_logger/inbound_request_log"
require "rails_api_logger/outbound_request_log"
require "rails_api_logger/inbound_requests_logger"
require "rails_api_logger/inbound_requests_logger_middleware"

module RailsApiLogger
  class Error < StandardError; end

  def self.call(uri, http, request)
    log = OutboundRequestLog.from_request(request)

    http.request(request).tap do |response|
      log.response_code = response.code
      log.response_body = response.body
    end
  rescue => e
    log.response_body = {error: e.message}
    raise
  ensure
    log.save!
  end
end
