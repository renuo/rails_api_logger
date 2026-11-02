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
    book = Book.create!(title: "My Book", author: "John Doe")
    attach_inbound_request_loggable(book)
    attach_inbound_request_client_reference("ref-123")

    [200, {}, @response_body]
  end

  def request
    @request ||= Rack::Request.new(@env)
  end
end

class MyTransactionalApp < MyApp
  def call(env)
    ActiveRecord::Base.transaction do
      super.tap { Book.create!(title: "Another Book", author: "John Doe") }
    end
  end
end

RSpec.describe RailsApiLogger::Middleware do
  let(:input) { {"book" => {"title" => "Harry Potter", "author" => "J.K. Rowling"}} }
  let(:host_regexp) { /.*/ }
  let(:path_regexp) { /.*/ }
  let(:skip_request_body_regexp) { nil }
  let(:skip_response_body_regexp) { nil }
  let(:app) do
    described_class.new(MyApp.new,
      host_regexp: host_regexp,
      path_regexp: path_regexp,
      skip_request_body_regexp: skip_request_body_regexp,
      skip_response_body_regexp: skip_response_body_regexp)
  end
  let(:request) { Rack::MockRequest.new(app) }
  let(:response) { request.post("http://api.example.org/api/v1/books", {input: input.to_json}) }

  before do
    RailsApiLogger::InboundRequestLog.delete_all
  end

  after do
    RailsApiLogger::InboundRequestLog.delete_all
  end

  context "when the HTTP_HOST matches the host_regexp" do
    let(:host_regexp) { /api.example.org/ }

    it "logs a request in the database" do
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
      inbound_request_log = RailsApiLogger::InboundRequestLog.first
      expect(inbound_request_log.method).to eq("POST")
      expect(inbound_request_log.path).to eq("/api/v1/books")
      expect(inbound_request_log.request_body).to eq(input)
      expect(inbound_request_log.response_code).to eq(200)
      expect(inbound_request_log.response_body).to eq("Hello World")
      expect(inbound_request_log.started_at).to be_present
      expect(inbound_request_log.ended_at).to be_present
      expect(inbound_request_log.duration).to be > 0
      expect(inbound_request_log.loggable_type).to eq("Book")
      expect(inbound_request_log.loggable_id).to be_present
      expect(inbound_request_log.client_reference).to eq("ref-123")
    end
  end

  context "when the PATH_INFO matches the path_regexp" do
    let(:path_regexp) { /\/api/ }

    it "logs a request in the database" do
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
      inbound_request_log = RailsApiLogger::InboundRequestLog.first
      expect(inbound_request_log.method).to eq("POST")
      expect(inbound_request_log.path).to eq("/api/v1/books")
      expect(inbound_request_log.request_body).to eq(input)
      expect(inbound_request_log.response_code).to eq(200)
      expect(inbound_request_log.response_body).to eq("Hello World")
      expect(inbound_request_log.started_at).to be_present
      expect(inbound_request_log.ended_at).to be_present
      expect(inbound_request_log.duration).to be > 0
      expect(inbound_request_log.loggable_type).to eq("Book")
      expect(inbound_request_log.loggable_id).to be_present
    end

    context "when the PATH_INFO matches the skip_request_body_regexp" do
      let(:skip_request_body_regexp) { /books/ }

      it "logs a request in the database but without a request body" do
        expect(response.status).to eq(200)
        expect(response.body).to eq("Hello World")
        expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
        inbound_request_log = RailsApiLogger::InboundRequestLog.first
        expect(inbound_request_log.method).to eq("POST")
        expect(inbound_request_log.path).to eq("/api/v1/books")
        expect(inbound_request_log.request_body).to eq("[Skipped]")
        expect(inbound_request_log.response_code).to eq(200)
        expect(inbound_request_log.response_body).to eq("Hello World")
      end
    end

    context "when the PATH_INFO matches the skip_response_body_regexp" do
      let(:skip_response_body_regexp) { /books/ }

      it "logs a request in the database but without a response body" do
        expect(response.status).to eq(200)
        expect(response.body).to eq("Hello World")
        expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
        inbound_request_log = RailsApiLogger::InboundRequestLog.first
        expect(inbound_request_log.method).to eq("POST")
        expect(inbound_request_log.path).to eq("/api/v1/books")
        expect(inbound_request_log.request_body).to eq(input)
        expect(inbound_request_log.response_code).to eq(200)
        expect(inbound_request_log.response_body).to eq("[Skipped]")
      end
    end

    context "when the response body contains invalid UTF-8" do
      let(:app) do
        RailsApiLogger::Middleware.new(MyApp.new(response_body: "iPhone\xAE"), path_regexp: path_regexp)
      end

      it "logs a request in the database with the size of the body" do
        expect(response.status).to eq(200)
        expect(response.body).to eq("iPhone\xAE")
        expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
        inbound_request_log = RailsApiLogger::InboundRequestLog.first
        expect(inbound_request_log.response_code).to eq(200)
        expect(inbound_request_log.response_body).to eq("[Binary: 7 bytes]")
      end
    end
  end

  context "when the HTTP_HOST does not match the host_regexp" do
    let(:host_regexp) { /foo.example.com/ }

    it "does not log the request" do
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(RailsApiLogger::InboundRequestLog.count).to eq(0)
    end
  end

  context "when the PATH_INFO does not match the path_regexp" do
    let(:path_regexp) { /\/pupu/ }

    it "does not log the request" do
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(RailsApiLogger::InboundRequestLog.count).to eq(0)
    end
  end

  context "when the logging database is down" do
    before { simulate_logging_database_outage }
    after { restore_logging_database }

    it "still runs the app and reports the error" do
      expect { response }.to change(Book, :count).by(1)
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(logging_errors).not_to be_empty
    end
  end

  context "when the log can't be completed after the app ran" do
    before { make_logs_fail(RailsApiLogger::InboundRequestLog, :update_columns) }

    it "still returns the response of the app" do
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(logging_errors).to include(an_instance_of(ActiveRecord::StatementInvalid))
    end
  end

  context "when attaching the loggable or the client reference fails" do
    before { make_logs_fail(RailsApiLogger::InboundRequestLog, :update) }

    it "still returns the response of the app and logs it" do
      expect(response.status).to eq(200)
      expect(logging_errors).to include(an_instance_of(ActiveRecord::StatementInvalid))
      inbound_request_log = RailsApiLogger::InboundRequestLog.last
      expect(inbound_request_log.response_code).to eq(200)
      expect(inbound_request_log.loggable).to be_nil
    end

    context "inside a transaction of the app" do
      let(:app) { described_class.new(MyTransactionalApp.new) }

      before { make_logs_fail(RailsApiLogger::InboundRequestLog, :update) { fail_in_database } }

      it "keeps the transaction of the app usable" do
        expect { response }.to change(Book, :count).by(2)
        expect(response.status).to eq(200)
        expect(logging_errors).to include(an_instance_of(ActiveRecord::StatementInvalid))
      end
    end
  end

  context "when the app attaches the loggable inside a transaction" do
    let(:app) { described_class.new(MyTransactionalApp.new) }

    it "logs the request with the loggable" do
      expect(response.status).to eq(200)
      inbound_request_log = RailsApiLogger::InboundRequestLog.last
      expect(inbound_request_log.loggable_type).to eq("Book")
      expect(inbound_request_log.client_reference).to eq("ref-123")
      expect(logging_errors).to be_empty
    end
  end

  context "when ActiveRecord.permanent_connection_checkout is :disallowed" do
    around { |example| with_permanent_connection_checkout_disallowed(&example) }

    it "logs the request" do
      expect(response.status).to eq(200)
      expect(logging_errors).to be_empty
      expect(RailsApiLogger::InboundRequestLog.last.response_code).to eq(200)
    end
  end

  context "when a file is uploaded" do
    let(:file) do
      Tempfile.new(["image", ".png"]).tap do |f|
        f.binmode
        f.write("\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\xFF\xFE".b)
        f.rewind
      end
    end
    let(:upload) { Rack::Multipart::UploadedFile.new(file.path, "image/png", true) }
    let(:response) do
      env = Rack::MockRequest.env_for("http://api.example.org/api/v1/books", method: "POST", params: {image: upload})
      request.post("http://api.example.org/api/v1/books", :input => env["rack.input"].read,
        "CONTENT_TYPE" => env["CONTENT_TYPE"])
    end

    it "logs the request with the size of the body instead of its bytes" do
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
      expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
      expect(RailsApiLogger::InboundRequestLog.last.request_body).to match(/\A\[Binary: \d+ bytes\]\z/)
    end
  end
end
