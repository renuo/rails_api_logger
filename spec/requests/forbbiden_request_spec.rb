require "rails_helper"

RSpec.describe "request blocked by rack attack", type: :request do
  before do
    RailsApiLogger::InboundRequestLog.delete_all
  end

  describe "/test/forbidden" do
    it "does not log the request" do
      get "/test/forbidden"
      expect(RailsApiLogger::InboundRequestLog.count).to eq(0)
    end
  end
end
