class CreateRailsApiLoggerTable < ActiveRecord::Migration[Rails.version.split(".")[0..1].join(".")]
  def change
    create_table :inbound_request_logs do |t|
      t.string :method
      t.string :path
      t.text :request_body
      t.text :response_body
      t.integer :response_code
      t.timestamp :started_at
      t.timestamp :ended_at
      t.references :loggable, index: true, polymorphic: true
      t.timestamps null: false
    end

    create_table :outbound_request_logs do |t|
      t.string :method
      t.string :path
      t.text :request_body
      t.text :response_body
      t.integer :response_code
      t.timestamp :started_at
      t.timestamp :ended_at
      t.references :loggable, index: true, polymorphic: true
      t.timestamps null: false
    end
  end
end
