module InboundRequestsLogger
  extend ActiveSupport::Concern

  private

  def attach_inbound_request_loggable(loggable)
    request.env["INBOUND_REQUEST_LOG"].update(loggable: loggable) if loggable&.persisted?
  end
end
