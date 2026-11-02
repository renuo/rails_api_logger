ENV["RAILS_ENV"] = "test"
ENV["RACK_ENV"] = "test"

require "bundler/setup"
require "net/http"
require_relative "../spec/dummy/config/environment"

require "webmock/rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    stub_request(:any, /example.com/).to_return(status: 200, body: "here is my response")
    stub_request(:any, /httpbin.org/).to_return(status: 200, body: "here is my response")
  end
end

module LoggingFailureHelpers
  class ReportedErrors
    attr_reader :errors

    def initialize
      @errors = []
    end

    def report(error, source:, **)
      errors << error if source == "rails_api_logger"
    end
  end

  def logging_errors
    @reported_errors.errors
  end

  def make_logs_fail(log_class, method, &failure)
    failure ||= proc { raise ActiveRecord::StatementInvalid }
    allow(log_class).to receive(:from_request).and_wrap_original do |original, *args, **kwargs|
      original.call(*args, **kwargs).tap { |log| allow(log).to receive(method, &failure) }
    end
  end

  def fail_in_database
    RailsApiLogger::RequestLog.with_connection { |connection| connection.execute("SELECT * FROM missing_table") }
  end

  def simulate_logging_database_outage
    config = RailsApiLogger::RequestLog.connection_db_config.configuration_hash
    unreachable = (config[:adapter] == "sqlite3") ? {database: "/nonexistent/logs.sqlite3"} : {host: "127.0.0.1", port: 1}
    RailsApiLogger::RequestLog.establish_connection(config.merge(unreachable))
  end

  def restore_logging_database
    RailsApiLogger::RequestLog.remove_connection
    RailsApiLogger::RequestLog.connects_to(**RailsApiLogger.connects_to) if RailsApiLogger.connects_to
  end

  def with_permanent_connection_checkout_disallowed
    previous = ActiveRecord.permanent_connection_checkout
    ActiveRecord.permanent_connection_checkout = :disallowed
    ActiveRecord::Base.connection_handler.clear_active_connections!(:all)
    yield
  ensure
    ActiveRecord.permanent_connection_checkout = previous
  end
end

RSpec.configure do |config|
  config.include LoggingFailureHelpers

  config.before do
    @reported_errors = LoggingFailureHelpers::ReportedErrors.new
    Rails.error.subscribe(@reported_errors)
  end

  config.after do
    Rails.error.unsubscribe(@reported_errors)
  end
end
