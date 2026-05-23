# frozen_string_literal: true

require "mcp"

module RailsMcp
  module Tools
    class CountRecords < MCP::Tool
      tool_name "count_records"
      description "Count records matching hash conditions"
      input_schema(
        properties: {
          model:      { type: "string", description: "Model class name, e.g. \"User\"" },
          conditions: { type: "object", description: "Hash of column => value pairs" }
        },
        required: ["model"]
      )

      def self.call(model:, server_context:, conditions: {})
        count = Database::RoleProxy.with_role do
          klass      = Database::ModelResolver.resolve(model)
          conditions = (conditions || {}).transform_keys(&:to_s)

          unknown = conditions.keys - klass.column_names
          raise Database::QueryBuilder::Error, "Unknown column(s): #{unknown.join(", ")}" if unknown.any?

          klass.where(conditions).count
        end
        MCP::Tool::Response.new([{ type: "text", text: { count: count }.to_json }])
      end
    end
  end
end
