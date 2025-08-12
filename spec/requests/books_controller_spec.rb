require "rails_helper"

RSpec.describe Api::BooksController, type: :request do
  before do
    RailsApiLogger::InboundRequestLog.delete_all
    Book.delete_all
  end

  describe "#index" do
    it "logs the request" do
      get "/api/books"
      expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
    end
  end

  describe "#create" do
    it "logs the request" do
      post "/api/books"
      expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
    end
  end

  describe "#update" do
    describe "if the request fails" do
      it "rolls back the transaction but persists the log" do
        book = Book.create!(title: "Harry Potter", author: "JK Rowling")

        put main_app.api_book_path(book), params: {book: {title: ""}}
        expect(RailsApiLogger::InboundRequestLog.count).to eq(1)
        expect(Book.count).to eq(1)
        expect(book.reload.title).to eq("Harry Potter")
      end
    end
  end
end
