require "rails_helper"

RSpec.describe Book do
  it "has outbound_request_logs" do
    book = Book.create!(title: "Little", author: "Big")
    expect(book.outbound_request_logs).to be_empty
    expect(book.inbound_request_logs).to be_empty
  end
end
