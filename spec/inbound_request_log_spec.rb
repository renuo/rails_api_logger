require "spec_helper"

RSpec.describe InboundRequestLog do
  before do
    allow(InboundRequestLog).to receive(:switch_tenant).and_return(nil)
  end
  
  it "encrypts any passwords before storing" do
    request_body = { "grant_type": "password", "email": "jane@doe.io", "password": "1234" }
    request_log = InboundRequestLog.create(path: "/oauth/token/", request_body: request_body, method: 'POST', started_at: Time.current)

    expect(request_log.request_body["password"]).not_to eq "1234"
  end

  it "encrypts any access tokens before storing" do
    request_body = { "grant_type": "password", "email": "jane@doe.io", "password": "1234" }
    response_body = { 
                      "access_token": "aagKUOMPwLNinhi3FHxMx0R5bhqN_u-40dL8HBJSzh4",
                      "token_type": "Bearer",
                      "expires_in": 7200
                    }
    request_log = InboundRequestLog.create(path: "/oauth/token/", request_body: request_body, method: "POST", started_at: Time.current)
    request_log.update(response_body: response_body, response_code: 200)
    expect(request_log.response_body["access_token"]).not_to eq "aagKUOMPwLNinhi3FHxMx0R5bhqN_u-40dL8HBJSzh4"
  end
end
