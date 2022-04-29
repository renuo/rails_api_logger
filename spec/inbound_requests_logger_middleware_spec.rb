require "spec_helper"
require "rack"
require "action_dispatch"

class MyApp
  def call(env)
    [200, {}, ["Hello World"]]
  end
end

RSpec.describe InboundRequestsLoggerMiddleware do
  it "logs a request in the database" do
    app = InboundRequestsLoggerMiddleware.new(MyApp.new)
    request = Rack::MockRequest.new(app)
    response = request.post("/")
    expect(response.status).to eq(200)
    expect(response.body).to eq("Hello World")
    expect(InboundRequestLog.count).to eq(1)
    inbound_request_log = InboundRequestLog.first
    expect(inbound_request_log.method).to eq("POST")
    expect(inbound_request_log.path).to eq("/")
    expect(inbound_request_log.request_body).to eq("")
    expect(inbound_request_log.response_code).to eq(200)
    expect(inbound_request_log.response_body).to eq(["Hello World"])
    expect(inbound_request_log.started_at).to be_present
    expect(inbound_request_log.ended_at).to be_present
    expect(inbound_request_log.duration).to be > 0
  end
end
