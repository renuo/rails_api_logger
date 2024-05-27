class InboundRequestLog < RequestLog
  require 'bcrypt'

  def request_body=(val)
    val[:password] = encrypted(val, :password) if present_in?(val, :password)
    self[:request_body] = val
  end

  def response_body=(val)
    val[:access_token] = encrypted(val, :access_token) if present_in?(val, :access_token)
    self[:response_body] = val
  end

  private

  def encrypted(val, attr)
    BCrypt::Password.create(val.with_indifferent_access[attr])
  end

  def present_in?(val, attr)
    val.is_a?(Hash) && (val.with_indifferent_access.key? attr)
  end
end
