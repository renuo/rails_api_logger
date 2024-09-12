require "spec_helper"

RSpec.describe RequestLog do
  describe ".failed" do
    [OutboundRequestLog, InboundRequestLog].each do |klass|
      it "returns only failed requests for #{klass}" do
        klass.create!(path: "/ok", method: "GET", response_code: 200)
        klass.create!(path: "/redirecting", method: "GET", response_code: 308)
        klass.create!(path: "/bad_request", method: "GET", response_code: 400)
        klass.create!(path: "/server_error", method: "GET", response_code: 500)
        klass.create!(path: "/long_and_still_running", method: "GET", response_code: nil, ended_at: nil)
        klass.create!(path: "/timeout", method: "GET", response_code: nil, ended_at: 1.hour.ago)

        expect(klass.failed).to contain_exactly(
          having_attributes(path: "/bad_request"),
          having_attributes(path: "/server_error"),
          having_attributes(path: "/timeout")
        )
      end
    end
  end

  describe "#from_response" do
    let(:uri) { URI("http://example.com/some_path?query=string") }
    let(:http) { Net::HTTP.new(uri.host, uri.port) }
    let(:request) { Net::HTTP::Get.new(uri) }
    let(:response) { http.start { |http| http.request(request) } }

    before { RailsApiLogger.new(skip_response_body: skip_response_body).call(uri, request) { response } }

    context "when skip_response_body is set to false" do
      let(:skip_response_body) { false }

      it "sets the response_body to the original request's response body" do
        log = OutboundRequestLog.last
        expect(log.response_body).to eq(response.body)
        expect(log.response_body).to be_present
      end
    end

    context "when skip_response_body is set to true" do
      let(:skip_response_body) { true }

      it "sets the response_body to [Skipped]" do
        log = OutboundRequestLog.last
        expect(log.response_body).to eq("[Skipped]")
      end
    end
  end
end
