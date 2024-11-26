# 0.10.0

**BREAKING CHANGES**

This version contains many breaking changes. Consider this when upgrading:

* Replace calls to `RailsApiLogger.new` with `RailsApiLogger::Logger.new`. More in general the logger has been renamed.
* `InboundRequestLog` has been renamed to `RailsApiLogger::InboundRequestLog`. Table name did not change.
* `OutboundRequestLog` has been renamed to `RailsApiLogger::OutboundRequestLog`. Table name did not change.
* If you had `has_many :inbound_request_logs` or `has_many :outbound_request_logs` defined, this will break. There's
  now [three methods](app/models/rails_api_logger/loggable.rb) you can use on your model.
* `InboundRequestsLoggerMiddleware` has been renamed to `RailsApiLogger::Middleware`

> Do the changes above and then continue with the following steps if you want to connect rails_api_logger to a different
database:

* Specify a database called `api_logger`. [Check here](spec/dummy/config/database.yml) for an example.
* Check that everything still works (also in production!) with the new configuration.
* Add the migrations in the right folder to create again the necessary tables. Run the migrations that will generate a
  new schema file.
* Release and do the same in production. Adapt your build/release steps if you need.

* Add the following line into `production.rb`:
  `config.rails_api_logger.connects_to = { database: { writing: :api_logger } }` if you want to point to a new database.

> If you are not on SQLite you can point also `api_logger` database to the current database you have, so you benefit from
isolated transactions but don't need to create a new database or migrate data.

### List of changes in this version:

* Namespace correctly. Renamed all classes
* Added tests with a dummy app
* Use a separate database connection configuration to isolate transactions
* I acknowledge that there might be issues on mysql. I don't use it so I won't fix them, but PR are welcome.
* Added `host_regexp` option to the middleware.

# 0.9.0

* Add option skip_request_body to skip the request body. Use this option when you don't want to persist the request
  body. `[Skipped]` will be persisted instead.
* Add option skip_request_body_regexp to skip logging the body of requests matching a regexp.
* Renamed the option skip_body into skip_response_body. This is a breaking change!
* Renamed the option skip_body_regexp into skip_response_body_regexp. This is a breaking change!

# 0.8.1

* Fix Rails 7.1 warnings.

# 0.8.0

* Add option skip_body to skip the body for request responses. Use this option when you don't want to persist the
  response body. `[Skipped]` will be persisted instead. This is not a breaking change.

# 0.7.0

* Fix an issue in the middleware where the request body was not read correctly if there were encoding issues.
* Improved documentation about outboud request logging.
* Add option skip_body_regexp to skip logging the body of requests matching a regexp.

# 0.6.3

* Fix the CHANGELOG path in gemspec.

# 0.6.2

* Fixes Zeitwerk warning.

# 0.6.1

* Fixes the loading of concern into controllers.

# 0.6.0

* Fixes an important concurrency issue by removing instance variables in the rack middleware.

# 0.5.0

* Started using Zeitwerk.
* Removed RailsAdmin specific code.
* Improved RailsApiLogger class.

# 0.4.1

* Fixed the `.failed` scope.

# 0.4.0

* Added `started_at`, `ended_at` and `duration` methods.

Migrate your tables with:

```
add_column :inbound_request_logs, :started_at, :timestamp
add_column :inbound_request_logs, :ended_at, :timestamp
add_column :outbound_request_logs, :started_at, :timestamp
add_column :outbound_request_logs, :ended_at, :timestamp
```

# 0.3.0

* Added `formatted_request_body` and `formatted_response_body` methods.

# 0.2.0

* Switch to a middleware solution.

# 0.1.0

* Initial release.
