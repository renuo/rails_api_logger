require "spec_helper"
require "faraday"

RSpec.describe RailsApiLogger::FaradayMiddleware do
  before do
    RailsApiLogger::OutboundRequestLog.delete_all
  end

  let(:connection) do
    Faraday.new(url: "https://example.com") do |f|
      f.use described_class, options
      f.adapter :test do |stub|
        stub.post("/users") { [201, {}, '{"id": 1, "name": "John"}'] }
        stub.get("/users/1") { [200, {}, '{"id": 1, "name": "John"}'] }
        stub.get("/error") { raise Faraday::ConnectionFailed, "connection failed" }
      end
    end
  end

  let(:options) { {} }

  describe "successful request" do
    it "logs the request and response" do
      response = connection.post("/users", {name: "John"}.to_json)

      expect(response.status).to eq(201)
      expect(RailsApiLogger::OutboundRequestLog.count).to eq(1)

      log = RailsApiLogger::OutboundRequestLog.last
      expect(log.path).to eq("https://example.com/users")
      expect(log.method).to eq("POST")
      expect(log.response_code).to eq(201)
      expect(log.started_at).to be_present
      expect(log.ended_at).to be_present
    end

    it "logs GET requests" do
      response = connection.get("/users/1")

      expect(response.status).to eq(200)

      log = RailsApiLogger::OutboundRequestLog.last
      expect(log.path).to eq("https://example.com/users/1")
      expect(log.method).to eq("GET")
      expect(log.response_code).to eq(200)
    end
  end

  describe "with skip_request_body option" do
    let(:options) { {skip_request_body: true} }

    it "does not log the request body" do
      connection.post("/users", {name: "John"}.to_json)

      log = RailsApiLogger::OutboundRequestLog.last
      expect(log.request_body).to eq("[Skipped]")
    end
  end

  describe "with skip_response_body option" do
    let(:options) { {skip_response_body: true} }

    it "does not log the response body" do
      connection.post("/users", {name: "John"}.to_json)

      log = RailsApiLogger::OutboundRequestLog.last
      expect(log.response_body).to eq("[Skipped]")
    end
  end

  describe "with loggable option" do
    let(:book) { Book.create!(title: "Test Book", author: "Author") }
    let(:options) { {loggable: book} }

    it "associates the log with the loggable" do
      connection.get("/users/1")

      log = RailsApiLogger::OutboundRequestLog.last
      expect(log.loggable).to eq(book)
    end
  end

  describe "when request fails" do
    it "logs the error and re-raises" do
      expect {
        connection.get("/error")
      }.to raise_error(Faraday::ConnectionFailed)

      log = RailsApiLogger::OutboundRequestLog.last
      expect(log.response_body).to eq({"error" => "connection failed"})
      expect(log.ended_at).to be_present
    end
  end
end
