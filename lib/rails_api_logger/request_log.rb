class RequestLog < ActiveRecord::Base
  self.abstract_class = true

  serialize :request_body, JSON
  serialize :response_body, JSON

  belongs_to :loggable, optional: true, polymorphic: true

  scope :failed, -> { where(response_code: 400..599).or(where.not(ended_at: nil).where(response_code: nil)) }

  validates :method, presence: true
  validates :path, presence: true

  def self.from_request(request, loggable: nil)
    request_body = (request.body.respond_to?(:read) ? request.body.read : request.body)
    body = request_body&.dup&.force_encoding("UTF-8")
    begin
      body = JSON.parse(body) if body.present?
    rescue JSON::ParserError
      body
    end
    create(path: request.path, request_body: body, method: request.method, started_at: Time.current, loggable: loggable)
  end

  def from_response(response)
    self.response_code = response.code
    body = response.body&.dup&.force_encoding("UTF-8")
    begin
      body = JSON.parse(body) if body.present?
    rescue JSON::ParserError
      body
    end
    self.response_body = body
    self
  end

  def formatted_request_body
    formatted_body(request_body)
  end

  def formatted_response_body
    formatted_body(response_body)
  end

  def formatted_body(body)
    if body.is_a?(Hash)
      JSON.pretty_generate(body)
    else
      xml = Nokogiri::XML(body)
      if xml.errors.any?
        body
      else
        xml.to_xml(indent: 2)
      end
    end
  rescue
    body
  end

  def duration
    return if started_at.nil? || ended_at.nil?
    ended_at - started_at
  end
end
