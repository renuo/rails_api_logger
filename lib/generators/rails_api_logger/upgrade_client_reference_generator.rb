# frozen_string_literal: true

require "rails/generators/base"
require "rails/generators/migration"

module RailsApiLogger
  module Generators
    class UpgradeClientReferenceGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("../../templates", __FILE__)

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      desc "Add the client_reference column to the rails_api_logger tables."
      def copy_migration
        migration_template "add_client_reference_to_rails_api_logger_tables.rb",
          "db/migrate/add_client_reference_to_rails_api_logger_tables.rb"
      end
    end
  end
end
