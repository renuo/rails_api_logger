RSpec.describe RailsApiLogger do
  before do
    ActiveRecord::Base.logger = nil
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Migration.verbose = false

    # TODO: copy-pasted from the migration template. avoid this. how? 🤷‍

    ActiveRecord::Schema.define do
      create_table :inbound_request_logs do |t|
        t.string :method
        t.string :path
        t.text :request_body
        t.text :response_body
        t.integer :response_code
        t.references :loggable, index: true, polymorphic: true
        t.timestamps null: false
      end

      create_table :outbound_request_logs do |t|
        t.string :method
        t.string :path
        t.text :request_body
        t.text :response_body
        t.integer :response_code
        t.references :loggable, index: true, polymorphic: true
        t.timestamps null: false
      end
    end
  end

  it "has a version number" do
    expect(RailsApiLogger::VERSION).not_to be nil
  end

  it "defines some models" do
    expect(InboundRequestLog.count).to eq(0)
    expect(OutboundRequestLog.count).to eq(0)
  end
end
