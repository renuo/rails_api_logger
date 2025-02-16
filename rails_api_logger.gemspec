require_relative "lib/rails_api_logger/version"

Gem::Specification.new do |spec|
  spec.name = "rails_api_logger"
  spec.version = RailsApiLogger::VERSION
  spec.authors = ["Alessandro Rodi"]
  spec.email = ["alessandro.rodi@renuo.ch"]

  spec.summary = "Log API requests like a king \u{1F451} "
  spec.description = "Log inbound and outbound API requests in your Rails application"
  spec.homepage = "https://github.com/renuo/rails_api_logger"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/renuo/rails_api_logger"
  spec.metadata["changelog_uri"] = "https://github.com/renuo/rails_api_logger/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  rails_version = ">= 6.0"
  spec.add_dependency "activerecord", rails_version
  spec.add_dependency "activejob", rails_version
  spec.add_dependency "railties", rails_version
  spec.add_dependency "nokogiri"
  spec.add_dependency "zeitwerk", ">= 2.0.0"

  spec.add_development_dependency "sqlite3", "~> 2.1.0"
  spec.add_development_dependency "pg", "~> 1.5.4"
  spec.add_development_dependency "mysql2", "~> 0.5.6"
  spec.add_development_dependency "standard", "~> 1.31"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "appraisal", "~> 2.5"
end
