require "spec_helper"

RSpec.describe OutboundRequestLog do
  it "logs a request in the database" do
    uri = URI("http://example.com/some_path?query=string")
    http = Net::HTTP.start(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)
    RailsApiLogger.call(uri, http, request)
    expect(OutboundRequestLog.count).to eq(1)
  end

  describe "#formatted_request_body" do
    it "renders the request body in a nice format" do
      outbound_request_log = OutboundRequestLog.new(request_body: {"my" => {"request" => "body"}})
      puts outbound_request_log.formatted_request_body
      expect { outbound_request_log.formatted_request_body }.not_to raise_error
      outbound_request_log.request_body = "simple text"
      puts outbound_request_log.formatted_request_body
      expect { outbound_request_log.formatted_request_body }.not_to raise_error
      outbound_request_log.request_body = "<i><a>Hello</a><b>From</b><c>XML</c></i>"
      puts outbound_request_log.formatted_request_body
      expect { outbound_request_log.formatted_request_body }.not_to raise_error
    end
  end
end
