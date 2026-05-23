# frozen_string_literal: true

require "rails_mcp/version"
require "rails_mcp/configuration"
require "rails_mcp/database/role_proxy"
require "rails_mcp/database/model_resolver"
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

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
