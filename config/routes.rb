# frozen_string_literal: true

RailsMcp::Engine.routes.draw do
  mount RailsMcp::Server.transport => "/"
  get "/.well-known/oauth-authorization-server", to: "rails_mcp/well_known#oauth_metadata"
end
