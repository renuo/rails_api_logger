require "active_record"
require "nokogiri"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.collapse("#{__dir__}/rails_api_logger")
loader.do_not_eager_load("#{__dir__}/generators")
loader.setup

class RailsApiLogger
  class Error < StandardError; end

  def initialize(loggable = nil)
    @loggable = loggable
  end

  def call(url, request)
    log = OutboundRequestLog.from_request(request, loggable: @loggable)
    yield.tap do |response|
      log.from_response(response)
    end
  rescue => e
    log.response_body = {error: e.message}
    raise
  ensure
    log.ended_at = Time.current
    log.save!
  end
end
