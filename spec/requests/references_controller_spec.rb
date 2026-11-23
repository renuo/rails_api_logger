require "rails_helper"

RSpec.describe Api::ReferencesController, type: :request do
  before { RailsApiLogger::InboundRequestLog.delete_all }

  it "can use the helpers in an ActionController::API controller" do
    post "/api/references"

    expect(response).to have_http_status(:no_content)
    expect(RailsApiLogger::InboundRequestLog.last.client_reference).to eq("ref-api")
  end
end
