module RailsApiLogger
  module Loggable
    def self.included(base)
      base.extend ClassMethods
    end

    # :nodoc:
    module ClassMethods
      def has_many_outbound_request_logs
        has_many :outbound_request_logs, -> { order(:created_at) },
          class_name: "RailsApiLogger::OutboundRequestLog",
          inverse_of: :loggable, dependent: :destroy, as: :loggable
      end

      def has_many_inbound_request_logs
        has_many :inbound_request_logs, -> { order(:created_at) },
          class_name: "RailsApiLogger::InboundRequestLog",
          inverse_of: :loggable, dependent: :destroy, as: :loggable
      end

      def has_many_request_logs
        has_many_inbound_request_logs
        has_many_outbound_request_logs
      end
    end
  end
end
