class RequestLog < ActiveRecord::Base
  self.abstract_class = true

  serialize :request_body, JSON
  serialize :response_body, JSON

  belongs_to :loggable, optional: true, polymorphic: true

  scope :failed, -> { where("response_code not like '2%'") }

  validates :method, presence: true
  validates :path, presence: true

  def self.from_request(request)
    body = (request.body.respond_to?(:read) ? request.body.read : request.body).dup.force_encoding("UTF-8")
    begin
      body = JSON.parse(body) if body.present?
    rescue JSON::ParserError
      body
    end
    create(path: request.path, request_body: body, method: request.method)
  end
end
