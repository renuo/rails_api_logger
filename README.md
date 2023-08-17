# Rails API Logger

The simplest way to log API requests of your Rails application in your database.

The Rails API logger gem introduces a set of tools to log and debug API requests.
It works on two sides:

* **Inbound requests**: API exposed by your application
* **Outbound requests**: API invoked by your application  

This gem has been extracted from various Renuo projects, where we implemented this
technique multiple times successfully.

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
spring stop # if it's running. otherwise it does not see the new generator 
bundle exec rails generate rails_api_logger:install
bundle exec rails db:migrate
```

This will generate two tables `inbound_request_logs` and `outbound_request_logs`.
These tables will contain the logs.

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

log = OutboundRequestLog.from_request(request)

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

response = RailsApiLogger.new.call(nil, request) do
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
end
``` 

This will guarantee that the log is always persisted, even in case of errors.

## Log Inbound Requests

If you are exposing some API you might be interested in logging the requests you receive.
You can do so by adding this middleware in `config/application.rb`

```ruby
config.middleware.insert_before Rails::Rack::Logger, InboundRequestsLoggerMiddleware
``` 

this will by default only log requests that have an impact in your system (POST, PUT, and PATCH calls).
If you want to log all requests (also GET ones) use

```ruby
config.middleware.insert_before Rails::Rack::Logger, InboundRequestsLoggerMiddleware, only_state_change: false
```

If you want to log only requests on a certain path, you can pass a regular expression:

```ruby
config.middleware.insert_before Rails::Rack::Logger, InboundRequestsLoggerMiddleware, path_regexp: /api/
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
has_many :inbound_request_logs, inverse_of: :loggable, dependent: :destroy, as: :loggable
```

to be able to access the logs attached to the model.

## RailsAdmin integration

We provide here some code samples to integrate the models in [RailsAdmin](https://github.com/sferik/rails_admin).

This configuration will give you some nice views, and searches to work with the logs efficiently. 
```ruby
%w[InboundRequestLog OutboundRequestLog].each do |logging_model|
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

## Caveats

If you log your requests inside of parent app transactions, your logs will not be persisted if
the transaction is rolled-back. You can circumvent that by opening another database connection
to the same (or another database if you're into that stuff) when logging.

```
# app/models/request_log.rb

module TransactionEscaping
  def self.prepended(_base)
    connects_to database: { writing: :primary, reading: :primary }
  end
end

RequestLog.prepend(TransactionEscaping)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/renuo/rails_api_logger. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to 
the [code of conduct](https://github.com/renuo/rails_api_logger/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RailsApiLogger project's codebases, issue trackers, chat rooms and mailing lists is 
expected to follow the [code of conduct](https://github.com/renuo/rails_api_logger/blob/main/CODE_OF_CONDUCT.md).
