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

  # Hide sensitive values in logged bodies with Rails' config.filter_parameters. Set to false to log them as they are.
  mattr_accessor :filter_parameters, default: true

  # Logging must never break the host app: report the error and go on without the log.
  # Inside an open transaction the log runs in a savepoint, so that a failed write
  # doesn't abort the transaction of the app (Postgres).
  # A connection that is not leased yet can't have an open transaction, so we don't lease one just to ask:
  # with `permanent_connection_checkout = :disallowed` that would raise and no log would ever be written.
  def self.safely(&block)
    if RequestLog.connection_pool.active_connection?&.transaction_open?
      RequestLog.transaction(requires_new: true, &block)
    else
      yield
    end
  rescue => e
    Rails.error.report(e, handled: true, source: "rails_api_logger")
    nil
  end
end
