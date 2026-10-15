require_relative "../app/models/rails_api_logger/loggable"
require_relative "../app/middlewares/rails_api_logger/middleware"
require "rails_api_logger/version"
require "rails_api_logger/engine"

require "rails"
require "nokogiri"

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.setup

module RailsApiLogger
  mattr_accessor :connects_to

  # Logging must never break the host app: report the error and go on without the log.
  # Inside an open transaction the log runs in a savepoint, so that a failed write
  # doesn't abort the transaction of the app (Postgres).
  def self.safely(&block)
    if RequestLog.connection.transaction_open?
      RequestLog.transaction(requires_new: true, &block)
    else
      yield
    end
  rescue => e
    if Rails.respond_to?(:error)
      Rails.error.report(e, handled: true)
    else
      Rails.logger.error("[RailsApiLogger] #{e.class}: #{e.message}")
    end
    nil
  end
end
