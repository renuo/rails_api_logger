require "spec_helper"

RSpec.describe RailsApiLogger::OutboundRequestLog do
  before do
    described_class.delete_all
    Book.delete_all
  end

  after do
    described_class.delete_all
  end

  describe "logging of a request" do
    let(:skip_request_body) { false }
    let(:skip_response_body) { false }

    before do
      uri = URI("https://httpbin.org/anything?query=string")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri)
      request.body = {"my" => {"request" => "body"}}.to_json
      RailsApiLogger::Logger.new(client_reference: "ref-abc",
        skip_request_body: skip_request_body, skip_response_body: skip_response_body)
        .call(uri, request) { http.start { |http| http.request(request) } }
    end

    it "logs all information" do
      expect(described_class.count).to eq(1)
      log = described_class.last
      expect(log.started_at).to be_present
      expect(log.ended_at).to be_present
      expect(log.request_body).to be_present
      expect(log.response_body).to be_present
      expect(log.client_reference).to eq("ref-abc")
    end

    describe "if the skip_request_body option is set" do
      let(:skip_request_body) { true }

      it "does not log the request body" do
        log = described_class.last
        expect(log.request_body).to eq("[Skipped]")
      end
    end

    describe "if the skip_response_body option is set" do
      let(:skip_response_body) { true }

      it "does not log the response body" do
        log = described_class.last
        expect(log.response_body).to eq("[Skipped]")
      end
    end
  end

  describe "if the request fails" do
    it "rolls back the transaction but persists the log" do
      Book.transaction do
        book = Book.create!(title: "The Lord of the rings", author: "DHH")

        uri = URI("http://example.com/some_path?query=string")
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri)

        RailsApiLogger::Logger.new(book).call(uri, request) { http.start { |http| http.request(request) } }

        raise ActiveRecord::Rollback
      end

      expect(Book.count).to eq(0)
      # if we are using the same connection, the transaction will roll back also the logging
      if ENV.fetch("SAME_DB", "false") == "true"
        expect(described_class.count).to eq(0)
      else
        expect(described_class.count).to eq(1)
        expect(described_class.last.loggable_type).to eq("Book")
        expect(described_class.last.loggable_id).to be_present
        expect(described_class.last.loggable).to be_nil
      end
    end
  end

  describe "#formatted_request_body" do
    it "renders the request body in a nice format" do
      outbound_request_log = described_class.new(request_body: {"my" => {"request" => "body"}})
      expect { outbound_request_log.formatted_request_body }.not_to raise_error
      outbound_request_log.request_body = "simple text"
      expect { outbound_request_log.formatted_request_body }.not_to raise_error
      outbound_request_log.request_body = "<i><a>Hello</a><b>From</b><c>XML</c></i>"
      expect { outbound_request_log.formatted_request_body }.not_to raise_error
      outbound_request_log.request_body = ""
      expect(outbound_request_log.formatted_request_body).to eq("")
    end
  end

  describe "#duration" do
    it "returns the request duration in seconds" do
      duration = described_class.new(started_at: 60.second.ago, ended_at: Time.current).duration
      expect(duration).to(be > 58)
      expect(duration).to(be < 62)
    end

    context "when one of the two values is not set" do
      it "returns nil" do
        expect(described_class.new.duration).to be_nil
        expect(described_class.new(started_at: 3.seconds.ago).duration).to be_nil
        expect(described_class.new(ended_at: 3.seconds.ago).duration).to be_nil
      end
    end
  end

  describe "if the log can't be written" do
    let(:uri) { URI("http://example.com/books") }
    let(:request) { Net::HTTP::Post.new(uri) }
    let(:response) { Struct.new(:code, :body).new(200, "ok") }

    context "because the logging database is down" do
      before { simulate_logging_database_outage }
      after { restore_logging_database }

      it "still sends the request and returns its response" do
        sent = false
        result = RailsApiLogger::Logger.new.call(uri, request) do
          sent = true
          response
        end

        expect(sent).to be(true)
        expect(result).to eq(response)
        expect(logging_errors).not_to be_empty
      end
    end

    context "because saving it fails" do
      before { make_logs_fail(described_class, :save!) }

      it "still returns the response" do
        expect(RailsApiLogger::Logger.new.call(uri, request) { response }).to eq(response)
        expect(logging_errors).to include(an_instance_of(ActiveRecord::StatementInvalid))
      end

      it "still raises the error of the request" do
        expect {
          RailsApiLogger::Logger.new.call(uri, request) { raise Timeout::Error }
        }.to raise_error(Timeout::Error)
      end
    end

    context "because reading the response fails" do
      let(:response) do
        Class.new do
          def code = 200

          def body = raise(IOError, "closed stream")
        end.new
      end

      it "still returns the response and logs the request without its body" do
        expect(RailsApiLogger::Logger.new.call(uri, request) { response }).to eq(response)
        expect(logging_errors).to include(an_instance_of(IOError))
        log = described_class.last
        expect(log.response_code).to eq(200)
        expect(log.response_body).to be_nil
        expect(log.ended_at).to be_present
      end
    end

    context "because a value doesn't fit its column", if: ENV["TARGET_DB"] == "mysql" do
      let(:uri) { URI("http://example.com/#{"a" * 300}") }

      it "still returns the response" do
        expect(RailsApiLogger::Logger.new.call(uri, request) { response }).to eq(response)
        expect(logging_errors).to include(an_instance_of(ActiveRecord::ValueTooLong))
      end
    end

    # These only abort the transaction on Postgres with a shared connection: the savepoint is what keeps it usable.
    context "inside a transaction of the app" do
      def call_inside_transaction
        ActiveRecord::Base.transaction do
          Book.create!(title: "Before", author: "Author")
          RailsApiLogger::Logger.new.call(uri, request) { response }
          Book.create!(title: "After", author: "Author")
        end
      end

      it "keeps the transaction usable when creating the log fails" do
        allow(described_class).to receive(:from_request) { fail_in_database }

        call_inside_transaction

        expect(Book.count).to eq(2)
        expect(logging_errors).to include(an_instance_of(ActiveRecord::StatementInvalid))
      end

      it "keeps the transaction usable when saving the log fails" do
        make_logs_fail(described_class, :save!) { fail_in_database }

        call_inside_transaction

        expect(Book.count).to eq(2)
        expect(logging_errors).to include(an_instance_of(ActiveRecord::StatementInvalid))
      end

      it "persists the log when the transaction commits" do
        call_inside_transaction

        expect(Book.count).to eq(2)
        expect(described_class.count).to eq(1)
        expect(described_class.last.ended_at).to be_present
        expect(logging_errors).to be_empty
      end
    end
  end

  describe "when ActiveRecord.permanent_connection_checkout is :disallowed" do
    around { |example| with_permanent_connection_checkout_disallowed(&example) }

    it "logs the request" do
      uri = URI("http://example.com/books")
      RailsApiLogger::Logger.new.call(uri, Net::HTTP::Post.new(uri)) { Struct.new(:code, :body).new(200, "ok") }

      expect(logging_errors).to be_empty
      expect(described_class.last.response_code).to eq(200)
    end
  end
end
