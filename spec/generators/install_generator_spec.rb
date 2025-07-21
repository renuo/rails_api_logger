# frozen_string_literal: true

require "rails_helper"
require "ammeter/init"
require "generators/rails_api_logger/install_generator"

# rubocop:disable Metrics/BlockLength
RSpec.describe RailsApiLogger::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../tmp", __dir__)

  before do
    prepare_destination
  end

  context "with default primary key (bigint)" do
    before do
      allow(Rails.application.config.generators).to receive_message_chain(:options, :[], :dig)
        .with(:active_record)
        .with(:primary_key_type)
        .and_return(nil)
    end

    it "generates migration without explicit id type" do
      run_generator

      migration = migration_file("db/migrate/create_rails_api_logger_table.rb")

      expect(migration).to contain("create_table :inbound_request_logs do")
      expect(migration).to contain("create_table :outbound_request_logs do")
      expect(migration).to contain("t.references :loggable, index: true, polymorphic: true")
      expect(migration).not_to contain("id: :uuid")
      expect(migration).not_to contain("type: :uuid")
    end
  end

  context "with UUID primary key" do
    before do
      allow(Rails.application.config.generators).to receive_message_chain(:options, :[], :dig)
        .with(:active_record)
        .with(:primary_key_type)
        .and_return(:uuid)
    end

    it "generates migration with uuid id type" do
      run_generator

      migration = migration_file("db/migrate/create_rails_api_logger_table.rb")

      expect(Pathname.new(migration)).to exist
      expect(migration).to contain("create_table :inbound_request_logs, id: :uuid do")
      expect(migration).to contain("create_table :outbound_request_logs, id: :uuid do")
      expect(migration).to contain("t.references :loggable, index: true, polymorphic: true, type: :uuid")
    end
  end

  context "with custom primary key type" do
    before do
      allow(Rails.application.config.generators).to receive_message_chain(:options, :[], :dig)
        .with(:active_record)
        .with(:primary_key_type)
        .and_return(:bigserial)
    end

    it "generates migration with custom id type" do
      run_generator

      migration = migration_file("db/migrate/create_rails_api_logger_table.rb")

      expect(Pathname.new(migration)).to exist
      expect(migration).to contain("create_table :inbound_request_logs, id: :bigserial do")
      expect(migration).to contain("create_table :outbound_request_logs, id: :bigserial do")
      expect(migration).to contain("t.references :loggable, index: true, polymorphic: true, type: :bigserial")
    end
  end

  private

  def migration_file(_file)
    migration_path = Dir.glob("#{destination_root}/db/migrate/*_create_rails_api_logger_table.rb").first

    file(migration_path)
  end
end
# rubocop:enable Metrics/BlockLength
