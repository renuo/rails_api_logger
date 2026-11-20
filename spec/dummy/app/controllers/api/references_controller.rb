# An API-only controller: ActionController::API does not inherit from ActionController::Base.
class Api::ReferencesController < ActionController::API
  def create
    attach_inbound_request_client_reference("ref-api")
    head :no_content
  end
end
