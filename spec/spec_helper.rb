require "bundler/setup"
require "net/http"
require "rails_api_logger"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    database_setup
  end
end

class Book < ActiveRecord::Base
end

def database_setup
  # ActiveRecord::Base.logger = nil
  ActiveRecord::Base.logger = Logger.new($stdout)

  # ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

  ActiveRecord::Base.establish_connection(adapter: "postgresql", database: "postgres")
  begin
    ActiveRecord::Base.connection.drop_database("rails_api_logger")
  rescue
    nil
  end
  begin
    ActiveRecord::Base.connection.create_database("rails_api_logger")
  rescue
    nil
  end
  ActiveRecord::Base.establish_connection(adapter: "postgresql", database: "rails_api_logger")

  ActiveRecord::Migration.verbose = false

  # TODO: copy-pasted from the migration template. avoid this. how? 🤷‍

  ActiveRecord::Schema.define do
    if !ActiveRecord::Base.connection.table_exists?(:inbound_request_logs)
      create_table :inbound_request_logs do |t|
        t.text :uuid
        t.string :method
        t.string :path
        t.text :request_body
        t.text :request_headers
        t.text :response_body
        t.text :response_headers
        t.integer :response_code
        t.inet :ip_used
        t.timestamp :started_at
        t.timestamp :ended_at
        t.references :loggable, index: true, polymorphic: true
        t.timestamps null: false
      end
    end

    if !ActiveRecord::Base.connection.table_exists?(:outbound_request_logs)
      create_table :outbound_request_logs do |t|
        t.text :uuid
        t.string :method
        t.string :path
        t.text :request_body
        t.text :request_headers
        t.text :response_body
        t.text :response_headers
        t.integer :response_code
        t.inet :ip_used
        t.timestamp :started_at
        t.timestamp :ended_at
        t.references :loggable, index: true, polymorphic: true
        t.timestamps null: false
      end
    end

    if !ActiveRecord::Base.connection.table_exists?(:books)
      create_table :books do |t|
        t.string :title
        t.string :author
        t.timestamps null: false
      end
    end
  end
end
