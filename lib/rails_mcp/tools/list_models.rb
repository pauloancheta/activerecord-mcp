# frozen_string_literal: true

require "mcp"

module RailsMcp
  module Tools
    class ListModels < MCP::Tool
      tool_name "list_models"
      description "List all accessible ActiveRecord model classes"
      input_schema(properties: {})

      def self.call(server_context:)
        models = Database::RoleProxy.with_role do
          Database::ModelResolver.all_accessible.map(&:name).sort
        end
        MCP::Tool::Response.new([{ type: "text", text: models.to_json }])
      end
    end
  end
end
