RSpec.describe RailsApiLogger do
  it "defines some models" do
    expect(InboundRequestLog.count).to eq(0)
    expect(OutboundRequestLog.count).to eq(0)
  end
end
