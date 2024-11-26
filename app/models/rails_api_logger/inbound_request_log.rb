module RailsApiLogger
  class InboundRequestLog < RequestLog
    self.table_name = "inbound_request_logs"
  end
end
