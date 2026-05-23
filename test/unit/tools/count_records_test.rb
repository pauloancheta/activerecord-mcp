# frozen_string_literal: true

require "test_helper"

class CountRecordsToolTest < ActiveSupport::TestCase
  setup do
    User.create!(name: "Alice", email: "alice@example.com", active: true)
    User.create!(name: "Bob",   email: "bob@example.com",   active: false)
  end

  test "counts all records" do
    response = call(model: "User")
    result   = JSON.parse(response.content.first[:text])
    assert_equal 2, result["count"]
  end

  test "counts with conditions" do
    response = call(model: "User", conditions: { "active" => true })
    result   = JSON.parse(response.content.first[:text])
    assert_equal 1, result["count"]
  end

  test "raises on unknown condition column" do
    assert_raises(RailsMcp::Database::QueryBuilder::Error) do
      call(model: "User", conditions: { "nonexistent" => 1 })
    end
  end

  test "raises on denied column in conditions" do
    RailsMcp.configuration.denied_columns = ["email"]
    err = assert_raises(RailsMcp::Database::QueryBuilder::Error) do
      call(model: "User", conditions: { "email" => "alice@example.com" })
    end
    assert_match "Unknown column(s)", err.message
  end

  test "raises on hash condition value" do
    err = assert_raises(RailsMcp::Database::QueryBuilder::Error) do
      call(model: "User", conditions: { "name" => { "starts_with" => "Al" } })
    end
    assert_match "Invalid condition value(s)", err.message
  end

  test "count oracle blocked for denied column" do
    RailsMcp.configuration.denied_columns = [/password/i]
    err = assert_raises(RailsMcp::Database::QueryBuilder::Error) do
      call(model: "User", conditions: { "password_digest" => "$2a$12$abc" })
    end
    assert_match "Unknown column(s)", err.message
  end

  private

  def call(**args)
    RailsMcp::Tools::CountRecords.call(server_context: {}, **args)
  end
end
