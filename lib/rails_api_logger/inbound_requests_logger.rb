module InboundRequestsLogger
  extend ActiveSupport::Concern

  private

  def attach_inbound_request_loggable(loggable)
    request.env["inbound_request_log"].update(loggable: loggable) if loggable&.persisted?
  end
end

ActiveSupport.on_load(:action_controller) do
  include InboundRequestsLogger
end
