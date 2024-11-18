require "spec_helper"
require "rspec/rails"

ENGINE_ROOT = File.join(File.dirname(__FILE__), "../")

begin
  ActiveRecord::Migrator.migrations_paths = File.join(ENGINE_ROOT, "spec/dummy/db/migrate")
  ActiveRecord::Migration.maintain_test_schema!
end
