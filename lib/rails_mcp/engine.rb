# frozen_string_literal: true

require "rails"
require "doorkeeper"

module RailsMcp
  class Engine < ::Rails::Engine
    isolate_namespace RailsMcp

    generators do
      require "generators/rails_mcp/install/install_generator"
    end

    config.middleware.use RailsMcp::Auth::TokenValidator

    initializer "rails_mcp.doorkeeper_pkce_check" do
      ActiveSupport.on_load(:after_initialize) do
        next unless defined?(Doorkeeper)

        methods = Doorkeeper.configuration.pkce_code_challenge_methods
        unless Array(methods).include?("S256")
          Rails.logger.warn "[activerecord-mcp] Doorkeeper PKCE S256 is not enabled. " \
                            "Add `pkce_code_challenge_methods %w[S256]` to your Doorkeeper config."
        end
      end
    end
  end
end
