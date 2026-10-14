module InboundRequestsLogger
  extend ActiveSupport::Concern

  private

  def attach_inbound_request_loggable(loggable)
    return unless request.env["INBOUND_REQUEST_LOG"].present?
    request.env["INBOUND_REQUEST_LOG"].update(loggable: loggable) if loggable&.persisted?
  end

  def attach_inbound_request_client_reference(client_reference)
    return unless request.env["INBOUND_REQUEST_LOG"].present?
    request.env["INBOUND_REQUEST_LOG"].update(client_reference: client_reference)
  end
end
