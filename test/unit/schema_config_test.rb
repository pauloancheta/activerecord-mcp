# frozen_string_literal: true

require "test_helper"

class SchemaConfigTest < ActiveSupport::TestCase
  FIXTURE = File.expand_path("../fixtures/rails_mcp.yml", __dir__)

  test "loads model names from YAML" do
    schema = RailsMcp::SchemaConfig.new(FIXTURE)
    assert_includes schema.model_names, "User"
    assert_includes schema.model_names, "Post"
  end

  test "accessible? returns true for listed models" do
    schema = RailsMcp::SchemaConfig.new(FIXTURE)
    assert schema.accessible?("User")
    assert schema.accessible?("Post")
  end

  test "accessible? returns false for unlisted models" do
    schema = RailsMcp::SchemaConfig.new(FIXTURE)
    refute schema.accessible?("Order")
  end

  test "allowed_columns returns columns for a model" do
    schema = RailsMcp::SchemaConfig.new(FIXTURE)
    assert_equal %w[id name created_at], schema.allowed_columns("User")
  end

  test "allowed_columns returns empty array for unknown model" do
    schema = RailsMcp::SchemaConfig.new(FIXTURE)
    assert_equal [], schema.allowed_columns("Ghost")
  end

  test "raises when file does not exist" do
    assert_raises(RailsMcp::SchemaConfig::Error) do
      RailsMcp::SchemaConfig.new("/nonexistent/path.yml")
    end
  end

  test "raises when file is not a mapping" do
    Tempfile.create(["schema", ".yml"]) do |f|
      f.write("- just_a_list\n")
      f.flush
      assert_raises(RailsMcp::SchemaConfig::Error) do
        RailsMcp::SchemaConfig.new(f.path)
      end
    end
  end

  test "raises when model name is invalid" do
    Tempfile.create(["schema", ".yml"]) do |f|
      f.write("lowercase:\n  - id\n")
      f.flush
      assert_raises(RailsMcp::SchemaConfig::Error) do
        RailsMcp::SchemaConfig.new(f.path)
      end
    end
  end

  test "raises when columns are not an array of strings" do
    Tempfile.create(["schema", ".yml"]) do |f|
      f.write("User: not_an_array\n")
      f.flush
      assert_raises(RailsMcp::SchemaConfig::Error) do
        RailsMcp::SchemaConfig.new(f.path)
      end
    end
  end
end

class SchemaConfigIntegrationTest < ActiveSupport::TestCase
  FIXTURE = File.expand_path("../fixtures/rails_mcp.yml", __dir__)

  setup do
    RailsMcp.configure { |c| c.schema_file = FIXTURE }
    User.create!(name: "Alice", email: "alice@example.com")
  end

  teardown do
    User.delete_all
  end

  test "ModelResolver only exposes listed models" do
    assert_equal User, RailsMcp::Database::ModelResolver.resolve("User")
    assert_raises(RailsMcp::Database::ModelResolver::AccessDenied) do
      # Doorkeeper models are not in the schema
      RailsMcp::Database::ModelResolver.resolve("Doorkeeper::Application")
    end
  end

  test "ModelResolver.all_accessible respects schema" do
    names = RailsMcp::Database::ModelResolver.all_accessible.map(&:name)
    assert_includes names, "User"
    assert_includes names, "Post"
    refute names.any? { |n| n.start_with?("Doorkeeper") }
  end

  test "QueryBuilder only allows schema columns" do
    # 'email' is NOT in the schema for User — must be rejected
    err = assert_raises(RailsMcp::Database::QueryBuilder::Error) do
      RailsMcp::Database::QueryBuilder.new(User, fields: ["email"]).execute
    end
    assert_match "Unknown field(s)", err.message
  end

  test "QueryBuilder allows schema columns" do
    results = RailsMcp::Database::QueryBuilder.new(User, fields: ["name"]).execute
    assert results.first.key?("name")
  end

  test "QueryBuilder rejects conditions on non-schema columns" do
    err = assert_raises(RailsMcp::Database::QueryBuilder::Error) do
      RailsMcp::Database::QueryBuilder.new(User, conditions: { "email" => "x" }).execute
    end
    assert_match "Unknown column(s) in conditions", err.message
  end

  test "schema_file takes precedence over allowed_models config" do
    RailsMcp.configure do |c|
      c.schema_file    = FIXTURE
      c.allowed_models = ["Post"]  # would normally block User
    end
    # schema_file wins — User is accessible because it's in the YAML
    assert_equal User, RailsMcp::Database::ModelResolver.resolve("User")
  end
end
