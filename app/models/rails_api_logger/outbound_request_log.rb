module RailsApiLogger
  class OutboundRequestLog < RequestLog
    self.table_name = "outbound_request_logs"
  end
end
