# frozen_string_literal: true

module RailsMcp
  class Configuration
    attr_accessor :database_role,
                  :default_fields,
                  :allowed_models,
                  :denied_models,
                  :denied_columns,
                  :max_limit,
                  :max_offset,
                  :schema_file,
                  :scope

    def initialize
      @database_role  = :reading
      @default_fields = %i[id created_at updated_at]
      @allowed_models = []
      @denied_models  = []
      @denied_columns = []
      @max_limit      = 100
      @max_offset     = 10_000
      @schema_file    = nil
      @scope          = "mcp"
    end

    def column_denied?(name)
      denied_columns.any? do |pattern|
        pattern.is_a?(Regexp) ? pattern.match?(name.to_s) : pattern.to_s == name.to_s
      end
    end
  end
end
