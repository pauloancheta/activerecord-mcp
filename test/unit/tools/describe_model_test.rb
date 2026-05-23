# frozen_string_literal: true

require "test_helper"

class DescribeModelToolTest < ActiveSupport::TestCase
  test "returns schema info for a model" do
    response = call(model: "User")
    result   = JSON.parse(response.content.first[:text])

    assert_equal "User",  result["model"]
    assert_equal "users", result["table"]
    assert_equal "id",    result["primary_key"]

    col_names = result["columns"].map { |c| c["name"] }
    assert_includes col_names, "name"
    assert_includes col_names, "email"
    assert_includes col_names, "age"
  end

  test "includes associations" do
    response     = call(model: "User")
    result       = JSON.parse(response.content.first[:text])
    assoc_names  = result["associations"].map { |a| a["name"] }
    assert_includes assoc_names, "posts"
  end

  test "raises on unknown model" do
    assert_raises(RailsMcp::Database::ModelResolver::UnknownModel) do
      call(model: "Ghost")
    end
  end

  private

  def call(**args)
    RailsMcp::Tools::DescribeModel.call(server_context: {}, **args)
  end
end
