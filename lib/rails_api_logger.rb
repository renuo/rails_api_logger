require "active_record"
require "nokogiri"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.collapse("#{__dir__}/rails_api_logger")
loader.setup

class RailsApiLogger
  VERSION = "0.5.0"

  class Error < StandardError; end

  def call(url, request)
    log = OutboundRequestLog.from_request(request)
    yield.tap do |response|
      log.response_code = response.code
      log.response_body = response.body
    end
  rescue => e
    log.response_body = {error: e.message}
    raise
  ensure
    log.ended_at = Time.current
    log.save!
  end
end
