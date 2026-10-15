module InboundRequestsLogger
  extend ActiveSupport::Concern

  private

  def attach_inbound_request_loggable(loggable)
    return unless request.env["INBOUND_REQUEST_LOG"].present?
    return unless loggable&.persisted?
    RailsApiLogger.safely { request.env["INBOUND_REQUEST_LOG"].update(loggable: loggable) }
  end

  def attach_inbound_request_client_reference(client_reference)
    return unless request.env["INBOUND_REQUEST_LOG"].present?
    RailsApiLogger.safely { request.env["INBOUND_REQUEST_LOG"].update(client_reference: client_reference) }
  end
end
