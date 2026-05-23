# frozen_string_literal: true

require "test_helper"

class ListModelsToolTest < ActiveSupport::TestCase
  test "returns sorted accessible model names" do
    response = RailsMcp::Tools::ListModels.call(server_context: {})
    models   = JSON.parse(response.content.first[:text])
    assert_includes models, "User"
    assert_includes models, "Post"
    assert_equal models.sort, models
  end

  test "respects denied_models config" do
    RailsMcp.configuration.denied_models = ["Post"]
    response = RailsMcp::Tools::ListModels.call(server_context: {})
    models   = JSON.parse(response.content.first[:text])
    refute_includes models, "Post"
    assert_includes models, "User"
  end
end
