# frozen_string_literal: true

require "rails_mcp/version"
require "rails_mcp/configuration"
require "rails_mcp/schema_config"
require "rails_mcp/database/role_proxy"
require "rails_mcp/database/model_resolver"
require "rails_mcp/database/column_policy"
require "rails_mcp/database/query_builder"
require "rails_mcp/tools/list_models"
require "rails_mcp/tools/describe_model"
require "rails_mcp/tools/query_records"
require "rails_mcp/tools/find_record"
require "rails_mcp/tools/count_records"
require "rails_mcp/tool_dsl"
require "rails_mcp/server"
require "rails_mcp/auth/token_validator"
require "rails_mcp/engine"

module RailsMcp
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def schema_config
      return nil unless configuration.schema_file

      @schema_config ||= SchemaConfig.new(configuration.schema_file)
    end

    def reset_configuration!
      @configuration = Configuration.new
      @schema_config = nil
    end
  end
end
