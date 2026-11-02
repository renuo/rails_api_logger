module RailsApiLogger
  module BodyCoder
    # Rails 8.1 turned ActiveRecord::Coders::JSON from a module into a class.
    RAILS_CODER = ActiveRecord::Coders::JSON.respond_to?(:load) ? ActiveRecord::Coders::JSON : ActiveRecord::Coders::JSON.new

    def self.dump(body)
      RAILS_CODER.dump(body)
    end

    # json 2 wrote duplicate keys for hashes mixing string and symbol keys; json 3 refuses to read them by default.
    def self.load(json)
      RAILS_CODER.load(json)
    rescue JSON::ParserError
      JSON.parse(json, allow_duplicate_key: true)
    end
  end
end
