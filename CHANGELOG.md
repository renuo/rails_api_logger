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
