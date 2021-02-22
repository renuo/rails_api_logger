module InboundRequestsLogger
  extend ActiveSupport::Concern

  private

  def log_inbound_request
    @inbound_request_log = InboundRequestLog.from_request(request)
    yield
    @inbound_request_log.update(response_body: JSON.parse(response.body), response_code: response.code)
  end

  def request_with_state_change?
    request.post? || request.put? || request.patch? || request.delete?
  end

  def request_without_body?
    request.get? || request.head? || request.options? || request.delete?
  end

  def attach_inbound_request_loggable(loggable)
    @inbound_request_log.loggable = loggable if loggable&.persisted?
  end
end

ActiveSupport.on_load(:action_controller) do
  include InboundRequestsLogger
end

ActiveSupport.on_load(:action_controller_api) do
  include InboundRequestsLogger
end
