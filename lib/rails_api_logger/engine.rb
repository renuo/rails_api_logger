require_relative '../../app/models/rails_api_logger/loggable'

module RailsApiLogger
  class Engine < ::Rails::Engine
    isolate_namespace RailsApiLogger

    config.generators do |g|
      g.test_framework :rspec
    end

    config.rails_api_logger = ActiveSupport::OrderedOptions.new

    initializer "rails_api_logger.config" do
      config.rails_api_logger.each do |name, value|
        RailsApiLogger.public_send(:"#{name}=", value)
      end
    end

    ActiveSupport.on_load(:action_controller) do
      include InboundRequestsLogger
    end

    ActiveSupport.on_load(:active_record) do
      include RailsApiLogger::Loggable
    end
  end
end
