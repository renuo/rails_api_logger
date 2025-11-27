module RailsApiLogger
  class RequestLog < ActiveRecord::Base
    self.abstract_class = true

    connects_to(**RailsApiLogger.connects_to) if RailsApiLogger.connects_to

    if Gem::Version.new(Rails.version) >= Gem::Version.new("7.1")
      serialize :request_body, coder: JSON
      serialize :response_body, coder: JSON
    else
      serialize :request_body, JSON
      serialize :response_body, JSON
    end

    belongs_to :loggable, optional: true, polymorphic: true

    scope :failed, -> { where(response_code: 400..599).or(where.not(ended_at: nil).where(response_code: nil)) }

    validates :method, presence: true
    validates :path, presence: true

    def self.from_request(request, loggable: nil, skip_request_body: false)
      request = normalize_request(request)
      if skip_request_body
        body = "[Skipped]"
      else
        request_body = (request.body.respond_to?(:read) ? request.body.read : request.body)
        body = request_body&.dup&.force_encoding("UTF-8")
        begin
          body = JSON.parse(body) if body.present?
        rescue JSON::ParserError
          body
        end
      end
      create(path: request.path, request_body: body, method: request.method, started_at: Time.current, loggable: loggable)
    end

    def from_response(response, skip_response_body: false)
      response = self.class.normalize_response(response)
      self.response_code = response.code
      self.response_body = skip_response_body ? "[Skipped]" : manipulate_body(response.body)
      self
    end

    def self.normalize_request(request)
      return request unless faraday_request?(request)

      NormalizedRequest.new(
        path: request.url.to_s,
        body: request.request_body,
        method: request.method.to_s.upcase
      )
    end

    def self.normalize_response(response)
      return response unless faraday_response?(response)

      NormalizedResponse.new(
        code: response.status,
        body: response.body
      )
    end

    def self.faraday_request?(request)
      defined?(Faraday::Env) && request.is_a?(Faraday::Env)
    end

    def self.faraday_response?(response)
      defined?(Faraday::Response) && response.is_a?(Faraday::Response)
    end

    NormalizedRequest = Struct.new(:path, :body, :method, keyword_init: true)
    NormalizedResponse = Struct.new(:code, :body, keyword_init: true)

    def formatted_request_body
      formatted_body(request_body)
    end

    def formatted_response_body
      formatted_body(response_body)
    end

    def formatted_body(body)
      if body.is_a?(String) && body.blank?
        ""
      elsif body.is_a?(Hash)
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

    private

    def manipulate_body(body)
      body_duplicate = body&.dup&.force_encoding("UTF-8")
      begin
        body_duplicate = JSON.parse(body_duplicate) if body_duplicate.present?
      rescue JSON::ParserError
        body_duplicate
      end
      body_duplicate
    end
  end
end
