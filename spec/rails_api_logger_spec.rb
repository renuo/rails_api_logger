RSpec.describe RailsApiLogger do
  it "defines some models" do
    expect(RailsApiLogger::InboundRequestLog.count).to eq(0)
    expect(RailsApiLogger::OutboundRequestLog.count).to eq(0)
  end
end
