require "spec_helper"
require "faraday"

RSpec.describe RailsApiLogger::RequestLog do
  before do
    RailsApiLogger::OutboundRequestLog.delete_all
    RailsApiLogger::InboundRequestLog.delete_all
  end
  describe ".faraday_request?" do
    it "returns true for Faraday::Env" do
      env = Faraday::Env.new
      expect(described_class.faraday_request?(env)).to be true
    end

    it "returns false for Net::HTTP request" do
      request = Net::HTTP::Get.new(URI("http://example.com"))
      expect(described_class.faraday_request?(request)).to be false
    end
  end

  describe ".faraday_response?" do
    it "returns true for Faraday::Response" do
      response = Faraday::Response.new
      expect(described_class.faraday_response?(response)).to be true
    end

    it "returns false for Net::HTTP response" do
      uri = URI("http://example.com")
      response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request(Net::HTTP::Get.new(uri)) }
      expect(described_class.faraday_response?(response)).to be false
    end
  end

  describe ".normalize_request" do
    context "with a Faraday::Env" do
      it "returns a NormalizedRequest with correct attributes" do
        env = Faraday::Env.new
        env.url = URI("https://api.example.com/users")
        env.method = :post
        env.request_body = '{"name":"John"}'

        normalized = described_class.normalize_request(env)

        expect(normalized.path).to eq("https://api.example.com/users")
        expect(normalized.method).to eq("POST")
        expect(normalized.body).to eq('{"name":"John"}')
      end
    end

    context "with a Net::HTTP request" do
      it "returns the request unchanged" do
        request = Net::HTTP::Get.new(URI("http://example.com"))
        expect(described_class.normalize_request(request)).to eq(request)
      end
    end
  end

  describe ".normalize_response" do
    context "with a Faraday::Response" do
      it "returns a NormalizedResponse with correct attributes" do
        response = Faraday::Response.new(status: 201, body: '{"id":1}')

        normalized = described_class.normalize_response(response)

        expect(normalized.code).to eq(201)
        expect(normalized.body).to eq('{"id":1}')
      end
    end

    context "with a Net::HTTP response" do
      it "returns the response unchanged" do
        uri = URI("http://example.com")
        response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request(Net::HTTP::Get.new(uri)) }
        expect(described_class.normalize_response(response)).to eq(response)
      end
    end
  end

  describe ".from_request with Faraday" do
    it "creates a log from a Faraday::Env" do
      env = Faraday::Env.new
      env.url = URI("https://api.example.com/users")
      env.method = :post
      env.request_body = '{"name":"John"}'

      log = RailsApiLogger::OutboundRequestLog.from_request(env)

      expect(log.path).to eq("https://api.example.com/users")
      expect(log.method).to eq("POST")
      expect(log.request_body).to eq({"name" => "John"})
      expect(log.started_at).to be_present
    end
  end

  describe "#from_response with Faraday" do
    it "updates the log from a Faraday::Response" do
      log = RailsApiLogger::OutboundRequestLog.create!(
        path: "https://api.example.com/users",
        method: "POST",
        started_at: Time.current
      )

      response = Faraday::Response.new(status: 201, body: '{"id":1}')
      log.from_response(response)

      expect(log.response_code).to eq(201)
      expect(log.response_body).to eq({"id" => 1})
    end
  end

  describe ".failed" do
    [RailsApiLogger::OutboundRequestLog, RailsApiLogger::InboundRequestLog].each do |klass|
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

    before { RailsApiLogger::Logger.new(skip_response_body: skip_response_body).call(uri, request) { response } }

    context "when skip_response_body is set to false" do
      let(:skip_response_body) { false }

      it "sets the response_body to the original request's response body" do
        log = RailsApiLogger::OutboundRequestLog.last
        expect(log.response_body).to eq(response.body)
        expect(log.response_body).to be_present
      end
    end

    context "when skip_response_body is set to true" do
      let(:skip_response_body) { true }

      it "sets the response_body to [Skipped]" do
        log = RailsApiLogger::OutboundRequestLog.last
        expect(log.response_body).to eq("[Skipped]")
      end
    end
  end
end
