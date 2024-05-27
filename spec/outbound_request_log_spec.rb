require "spec_helper"

RSpec.describe OutboundRequestLog do
  before do
    OutboundRequestLog.delete_all
  end

  before { allow(OutboundRequestLog).to receive(:switch_tenant).and_return(nil) }

  it "logs a request in the database" do
    uri = URI("http://example.com/some_path?query=string")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)
    RailsApiLogger.new.call(uri, request) { http.start { |http| http.request(request) } }
    expect(OutboundRequestLog.count).to eq(1)
    log = OutboundRequestLog.last
    expect(log.started_at).to be_present
    expect(log.ended_at).to be_present
  end

  describe "if the request fails" do
    it "rolls back the transaction but persists the log" do
      Book.transaction do
        book = Book.create!

        uri = URI("http://example.com/some_path?query=string")
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri)

        Thread.new {
          RailsApiLogger.new(book).call(uri, request) { http.start { |http| http.request(request) } }
        }.join

        raise ActiveRecord::Rollback
      end
      expect(OutboundRequestLog.count).to eq(1)
      expect(Book.count).to eq(0)
      expect(OutboundRequestLog.last.loggable_type).to eq("Book")
      expect(OutboundRequestLog.last.loggable_id).to be_present
      expect(OutboundRequestLog.last.loggable).to be_nil
    end
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

  describe "#duration" do
    it "returns the request duration in seconds" do
      duration = OutboundRequestLog.new(started_at: 60.second.ago, ended_at: Time.current).duration
      expect(duration).to(be > 58)
      expect(duration).to(be < 62)
    end

    context "when one of the two values is not set" do
      it "returns nil" do
        expect(OutboundRequestLog.new.duration).to be_nil
        expect(OutboundRequestLog.new(started_at: 3.seconds.ago).duration).to be_nil
        expect(OutboundRequestLog.new(ended_at: 3.seconds.ago).duration).to be_nil
      end
    end
  end
end
