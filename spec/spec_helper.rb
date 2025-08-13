ENV["RAILS_ENV"] = "test"
ENV["RACK_ENV"] = "test"

require "bundler/setup"
require "net/http"
require_relative "../spec/dummy/config/environment"

require 'webmock/rspec'

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
