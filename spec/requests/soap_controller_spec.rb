require "rails_helper"

RSpec.describe Api::SoapController, type: :request do
  before do
    RailsApiLogger::InboundRequestLog.delete_all
  end

  describe "#index" do
    it "does log the request" do
      get "/api/soap"
      expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
    end
  end
end
