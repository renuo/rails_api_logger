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
end
