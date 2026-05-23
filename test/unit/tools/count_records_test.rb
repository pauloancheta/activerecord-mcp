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

  private

  def call(**args)
    RailsMcp::Tools::CountRecords.call(server_context: {}, **args)
  end
end
