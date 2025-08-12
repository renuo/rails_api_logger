# simulates the presence of rack attack in the app, so we can check the behavior.
# We expect (by default) that requests blocked by rack attack are not logged by rails_api_logger
# since they are also not logged in the Rails logs.
class RackAttack
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"] == "/test/forbidden"
      [403, {"content-type" => "text/plain"}, ["Forbidden\n"]]
    else
      @app.call(env)
    end
  end
end
