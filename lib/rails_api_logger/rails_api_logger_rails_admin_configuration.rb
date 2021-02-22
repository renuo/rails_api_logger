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
