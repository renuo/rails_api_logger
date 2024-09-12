# 0.9.0 - Breaking changes ⚠️
* Add option skip_request_body to skip the request body. Use this option when you don't want to persist the request body. `[Skipped]` will be persisted instead.
* Add option skip_request_body_regexp to skip logging the body of requests matching a regexp.
* Renamed the option skip_body into skip_response_body. **This is a breaking change!**
* Renamed the option skip_body_regexp into skip_response_body_regexp. **This is a breaking change!**

# 0.8.1
* Fix Rails 7.1 warnings.

# 0.8.0
* Add option skip_body to skip the body for request responses. Use this option when you don't want to persist the response body. `[Skipped]` will be persisted instead. This is not a breaking change.

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
