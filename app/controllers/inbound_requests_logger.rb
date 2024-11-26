module InboundRequestsLogger
  extend ActiveSupport::Concern

  private

  def attach_inbound_request_loggable(loggable)
    return unless request.env["INBOUND_REQUEST_LOG"].present?
    request.env["INBOUND_REQUEST_LOG"].update(loggable: loggable) if loggable&.persisted?
  end
end
