class RailsApiLogger
  class Engine < ::Rails::Engine
    isolate_namespace RailsApiLogger

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
