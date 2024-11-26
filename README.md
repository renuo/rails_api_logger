# Rails API Logger

The simplest way to log API requests in your database.

The Rails API logger gem introduces a set of tools to log and debug API requests.

It works on two sides:

* **Inbound requests**: API exposed by your application
* **Outbound requests**: API invoked by your application

This gem has been extracted from various [Renuo](https://www.renuo.ch) projects.

This gem creates two database tables to log the following information:

* **path** the path/url invoked
* **method** the method used to invoke the API (get, post, put, etc...)
* **request_body** what was included in the request body
* **response_body** what was included in the response body
* **response_code** the HTTP response code of the request
* **started_at** when the request started
* **ended_at** when the request finished

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_api_logger'
```

And then execute:

```bash
bundle install
bin/rails g rails_api_logger:install
bin/rails db:migrate
```

This will generate two tables `inbound_request_logs` and `outbound_request_logs`.
These tables will contain the logs.

## Ensure logging of data

RailsApiLogger can use a separate database, to ensure that the logs are written in the database even if a
surrounding database transaction is rolled back.

Make sure to add the following in your `config/environments/production.rb`:

```ruby
config.rails_api_logger.connects_to = { database: { writing: :api_logger } }
```

and [configure a new database](spec/dummy/config/database.yml) accordingly.

> ⚠️ If you skip this step, rails_api_logger will use your primary database but a rollback will also rollback the
> writing of logs
> If you are not on SQLite you can point also `api_logger` to the same database! By doing so you can use a single
> database but still guarantee the writing of logs in an isolated transaction.

## Log Outbound Requests

Given an outbound request in the following format:

```ruby
uri = URI('http://example.com/some_path?query=string')
http = Net::HTTP.start(uri.host, uri.port)
request = Net::HTTP::Get.new(uri)
response = http.request(request)
```

you can log it by doing the following:

```ruby
uri = URI('http://example.com/some_path?query=string')
http = Net::HTTP.start(uri.host, uri.port)
request = Net::HTTP::Get.new(uri)

log = RailsApiLogger::OutboundRequestLog.from_request(request)

response = http.request(request)

log.response_body = response.body
log.response_code = response.code
log.save!
```

You can also use the provided logger class to do that in a simpler and safer manner:

```ruby
uri = URI('https://example.com/some_path')
request = Net::HTTP::Post.new(uri)
request.body = { answer: 42 }.to_json
request.content_type = 'application/json'

response = RailsApiLogger::Logger.new.call(nil, request) do
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
end
``` 

This will guarantee that the log is always persisted, even in case of errors.

### Database Transactions Caveats

If you log your outbound requests inside of parent app transactions, your logs will not be persisted if
the transaction is rolled-back. Use a separate database to prevent this.

## Log Inbound Requests

If you are exposing some API you might be interested in logging the requests you receive.
You can do so by adding this middleware in `config/application.rb`

```ruby
config.middleware.insert_before Rails::Rack::Logger, RailsApiLogger::Middleware
``` 

this will by default only log requests that have an impact in your system (POST, PUT, and PATCH calls).
If you want to log all requests (also GET ones) use

```ruby
config.middleware.insert_before Rails::Rack::Logger, RailsApiLogger::Middleware, only_state_change: false
```

If you want to log only requests on a certain path, you can pass a regular expression:

```ruby
config.middleware.insert_before Rails::Rack::Logger, RailsApiLogger::Middleware, path_regexp: /api/
```

If you want to log only requests on a certain host, you can also use a regular expression:

```ruby
config.middleware.insert_before Rails::Rack::Logger, RailsApiLogger::Middleware, host_regexp: /api.example.com/
```

If you want to skip logging the response or request body of certain requests, you can pass a regular expression:

```ruby
config.middleware.insert_before Rails::Rack::Logger, RailsApiLogger::Middleware,
                                skip_request_body_regexp: /api\/books/,
                                skip_response_body_regexp: /api\/letters/
```

In the implementation of your API, you can call any time `attach_inbound_request_loggable(model)`
to attach an already persisted model to the log record.

For example:

```ruby

def create
  @user = User.new(user_params)
  if @user.save
    attach_inbound_request_loggable(@user)
    render json: { id: @user.id }, status: :created
  else
    render json: @user.errors.details, status: :unprocessable_entity
  end
end
```

in the User model you can define:

```ruby
has_many_inbound_request_logs
```

to be able to access the inbound logs attached to the model.

You also have `has_many_outbound_request_logs` and `has_many_request_logs` that includes both.

## RailsAdmin integration

We provide here some code samples to integrate the models in [RailsAdmin](https://github.com/sferik/rails_admin).

This configuration will give you some nice views, and searches to work with the logs efficiently.

```ruby
%w[RailsApiLogger::InboundRequestLog RailsApiLogger::OutboundRequestLog].each do |logging_model|
  config.model logging_model do
    list do
      filters %i[method path response_code request_body response_body created_at]
      scopes [nil, :failed]

      include_fields :method, :path, :response_code, :created_at

      field :request_body, :string do
        visible false
        searchable true
        filterable true
      end

      field :response_body, :string do
        visible false
        searchable true
        filterable true
      end
    end

    show do
      include_fields :loggable, :method, :path, :response_code
      field(:created_at)
      field(:request_body) do
        formatted_value { "<pre>#{JSON.pretty_generate(bindings[:object].request_body)}</pre>".html_safe }
      end
      field(:response_body) do
        formatted_value { "<pre>#{JSON.pretty_generate(bindings[:object].response_body)}</pre>".html_safe }
      end
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/renuo/rails_api_logger.
This project is intended to be a safe, welcoming space for collaboration.

Try to be a decent human being while interacting with other people.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
