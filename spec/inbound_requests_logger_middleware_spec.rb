require "spec_helper"
require "rack"
require "action_dispatch"

class MyApp
  include InboundRequestsLogger

  def initialize(response_body: "Hello World")
    @response_body = response_body
  end

  def call(env)
    @env = env
    book = Book.create!
    attach_inbound_request_loggable(book)

    [200, {}, @response_body]
  end

  def request
    @request ||= Rack::Request.new(@env)
  end
end

RSpec.describe InboundRequestsLoggerMiddleware do
  let(:skip_body_regexp) { nil }
  let(:app) do
    InboundRequestsLoggerMiddleware.new(MyApp.new, path_regexp: path_regexp, skip_body_regexp: skip_body_regexp)
  end
  let(:request) { Rack::MockRequest.new(app) }
  let(:response) { request.post("/api/v1/books") }

  before do
    InboundRequestLog.delete_all
  end

  context "when the PATH_INFO matches the path_regexp" do
    let(:path_regexp) { /\/api/ }

    it "logs a request in the database" do
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(InboundRequestLog.count).to eq(1)
      inbound_request_log = InboundRequestLog.first
      expect(inbound_request_log.method).to eq("POST")
      expect(inbound_request_log.path).to eq("/api/v1/books")
      expect(inbound_request_log.request_body).to eq("")
      expect(inbound_request_log.response_code).to eq(200)
      expect(inbound_request_log.response_body).to eq("Hello World")
      expect(inbound_request_log.started_at).to be_present
      expect(inbound_request_log.ended_at).to be_present
      expect(inbound_request_log.duration).to be > 0
      expect(inbound_request_log.loggable_type).to eq("Book")
      expect(inbound_request_log.loggable_id).to be_present
    end

    context "when the PATH_INFO matches the skip_body_regexp" do
      let(:skip_body_regexp) { /books/ }

      it "logs a request in the database but without a body" do
        expect(response.status).to eq(200)
        expect(response.body).to eq("Hello World")
        expect(InboundRequestLog.count).to eq(1)
        inbound_request_log = InboundRequestLog.first
        expect(inbound_request_log.method).to eq("POST")
        expect(inbound_request_log.path).to eq("/api/v1/books")
        expect(inbound_request_log.request_body).to eq("")
        expect(inbound_request_log.response_code).to eq(200)
        expect(inbound_request_log.response_body).to be_nil
      end
    end

    context "when the response body contains invalid UTF-8" do
      let(:app) do
        InboundRequestsLoggerMiddleware.new(MyApp.new(response_body: "iPhone\xAE"), path_regexp: path_regexp)
      end

      it "logs a request in the database without body" do
        expect(response.status).to eq(200)
        expect(response.body).to eq("iPhone\xAE")
        expect(InboundRequestLog.count).to eq(1)
        inbound_request_log = InboundRequestLog.first
        expect(inbound_request_log.response_code).to eq(200)
        expect(inbound_request_log.response_body).to be_nil
      end
    end
  end

  context "when the PATH_INFO does not match the path_regexp" do
    let(:path_regexp) { /\/pupu/ }

    it "does not log the request" do
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(InboundRequestLog.count).to eq(0)
    end
  end
end
