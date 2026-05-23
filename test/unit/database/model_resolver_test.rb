# frozen_string_literal: true

require "test_helper"

class ModelResolverTest < ActiveSupport::TestCase
  test "resolves a valid model name" do
    assert_equal User, RailsMcp::Database::ModelResolver.resolve("User")
  end

  test "raises UnknownModel for non-existent constant" do
    assert_raises(RailsMcp::Database::ModelResolver::UnknownModel) do
      RailsMcp::Database::ModelResolver.resolve("Nonexistent")
    end
  end

  test "raises UnknownModel for non-AR class" do
    assert_raises(RailsMcp::Database::ModelResolver::UnknownModel) do
      RailsMcp::Database::ModelResolver.resolve("String")
    end
  end

  test "raises UnknownModel for path traversal attempt" do
    assert_raises(RailsMcp::Database::ModelResolver::UnknownModel) do
      RailsMcp::Database::ModelResolver.resolve("../../etc/passwd")
    end
  end

  test "raises UnknownModel for lowercase name" do
    assert_raises(RailsMcp::Database::ModelResolver::UnknownModel) do
      RailsMcp::Database::ModelResolver.resolve("user")
    end
  end

  test "denied_models blocks access" do
    RailsMcp.configuration.denied_models = ["User"]
    assert_raises(RailsMcp::Database::ModelResolver::AccessDenied) do
      RailsMcp::Database::ModelResolver.resolve("User")
    end
  end

  test "allowed_models restricts access" do
    RailsMcp.configuration.allowed_models = ["Post"]
    assert_raises(RailsMcp::Database::ModelResolver::AccessDenied) do
      RailsMcp::Database::ModelResolver.resolve("User")
    end
    assert_equal Post, RailsMcp::Database::ModelResolver.resolve("Post")
  end

  test "empty allowed_models permits all" do
    RailsMcp.configuration.allowed_models = []
    assert_equal User, RailsMcp::Database::ModelResolver.resolve("User")
  end

  test "all_accessible returns AR models respecting config" do
    RailsMcp.configuration.denied_models = ["Post"]
    models = RailsMcp::Database::ModelResolver.all_accessible.map(&:name)
    assert_includes models, "User"
    refute_includes models, "Post"
  end
end
