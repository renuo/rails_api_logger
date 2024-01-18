require "active_record"
require "nokogiri"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.collapse("#{__dir__}/rails_api_logger")
loader.ignore("#{__dir__}/generators")
loader.setup

class RailsApiLogger
  class Error < StandardError; end

  def initialize(loggable = nil, skip_body: false)
    @loggable = loggable
    @skip_body = skip_body
  end

  def call(url, request)
    log = OutboundRequestLog.from_request(request, loggable: @loggable)
    yield.tap do |response|
      log.from_response(response, skip_body: @skip_body)
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
