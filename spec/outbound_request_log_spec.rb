require "spec_helper"

RSpec.describe OutboundRequestLog do
  it "logs a request in the database" do
    uri = URI("http://example.com/some_path?query=string")
    http = Net::HTTP.start(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)
    RailsApiLogger.call(uri, http, request)
    expect(OutboundRequestLog.count).to eq(1)
  end
end
