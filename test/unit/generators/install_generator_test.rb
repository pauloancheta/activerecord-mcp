# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/rails_mcp/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests RailsMcp::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator_output", __dir__)
  setup :prepare_destination

  test "creates the initializer file" do
    run_generator
    assert_file "config/initializers/rails_mcp.rb"
  end

  test "initializer contains all config keys commented out" do
    run_generator
    assert_file "config/initializers/rails_mcp.rb" do |content|
      %w[
        database_role
        default_fields
        allowed_models
        denied_models
        denied_columns
        max_limit
        max_offset
        schema_file
        scope
      ].each do |key|
        assert_match(/#\s*config\.#{key}/, content, "Expected #{key} to be present and commented out")
      end
    end
  end

  test "initializer wraps config in RailsMcp.configure block" do
    run_generator
    assert_file "config/initializers/rails_mcp.rb" do |content|
      assert_match "RailsMcp.configure do |config|", content
    end
  end

  test "does not overwrite an existing initializer by default" do
    FileUtils.mkdir_p File.join(destination_root, "config/initializers")
    File.write(File.join(destination_root, "config/initializers/rails_mcp.rb"), "# existing content")

    run_generator [], behavior: :skip
    assert_file "config/initializers/rails_mcp.rb" do |content|
      assert_match "# existing content", content
    end
  end
end
