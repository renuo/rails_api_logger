require "rails_helper"

RSpec.describe Api::BooksController, type: :request do
  describe "#index" do
    it "does not log the request" do
      get "/api/books"
      expect(InboundRequestLog.count).to eq(0)
    end
  end

  describe "#create" do
    it "logs the request" do
      post "/api/books"
      expect(InboundRequestLog.count).to eq(1)
    end
  end
end
