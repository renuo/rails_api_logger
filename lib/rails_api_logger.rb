require_relative "../app/models/rails_api_logger/loggable"
require_relative "../app/middlewares/rails_api_logger/middleware"
require "rails_api_logger/version"
require "rails_api_logger/engine"

require "rails"
require "nokogiri"

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.ignore("#{__dir__}/../app/middlewares/rails_api_logger/faraday_middleware.rb")
loader.setup

module RailsApiLogger
  mattr_accessor :connects_to
end

if defined?(Faraday)
  require_relative "../app/middlewares/rails_api_logger/faraday_middleware"
end
