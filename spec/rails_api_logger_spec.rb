RSpec.describe RailsApiLogger do
  it "has a version number" do
    expect(RailsApiLogger::VERSION).not_to be nil
  end

  it "defines some models" do
    expect(InboundRequestLog.count).to eq(0)
    expect(OutboundRequestLog.count).to eq(0)
  end
end
