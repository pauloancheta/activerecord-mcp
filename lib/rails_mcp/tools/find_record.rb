# frozen_string_literal: true

require "mcp"

module RailsMcp
  module Tools
    class FindRecord < MCP::Tool
      tool_name "find_record"
      description "Find a single record by primary key"
      input_schema(
        properties: {
          model:  { type: "string",  description: "Model class name, e.g. \"User\"" },
          id:     { type: "integer", description: "Primary key value" },
          fields: { type: "array",   description: "Columns to return. Defaults to [id, created_at, updated_at]",
                    items: { type: "string" } }
        },
        required: %w[model id]
      )

      def self.call(model:, id:, server_context:, fields: [])
        result = Database::RoleProxy.with_role do
          klass  = Database::ModelResolver.resolve(model)
          record = klass.find_by(klass.primary_key => id)

          raise Database::ModelResolver::UnknownModel, "#{model} with id=#{id} not found" unless record

          resolved_fields = resolve_fields(Array(fields), klass)
          validate_fields!(resolved_fields, klass)
          resolved_fields.each_with_object({}) { |f, h| h[f] = record.public_send(f) }
        end
        MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
      end

      def self.resolve_fields(requested, klass)
        return requested unless requested.empty?

        RailsMcp.configuration.default_fields.map(&:to_s) & klass.column_names
      end

      def self.validate_fields!(fields, klass)
        unknown = fields.map(&:to_s) - klass.column_names
        raise Database::QueryBuilder::Error, "Unknown field(s): #{unknown.join(", ")}" if unknown.any?
      end

      private_class_method :resolve_fields, :validate_fields!
    end
  end
end
