require "active_record"
require "nokogiri"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.collapse("#{__dir__}/rails_api_logger")
loader.ignore("#{__dir__}/generators")
loader.setup

class RailsApiLogger
  class Error < StandardError; end

  def initialize(loggable = nil, skip_request_body: false, skip_response_body: false)
    @loggable = loggable
    @skip_request_body = skip_request_body
    @skip_response_body = skip_response_body
  end

  def call(url, request)
    log = OutboundRequestLog.from_request(request, loggable: @loggable, skip_request_body: @skip_request_body)
    yield.tap do |response|
      log.from_response(response, skip_response_body: @skip_response_body)
    end
  rescue => e
    log.response_body = {error: e.message}
    raise
  ensure
    log.ended_at = Time.current
    log.save!
  end
end

ActiveSupport.on_load(:action_controller) do
  include InboundRequestsLogger
end
