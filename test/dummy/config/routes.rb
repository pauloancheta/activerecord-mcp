# frozen_string_literal: true

Rails.application.routes.draw do
  use_doorkeeper
  mount RailsMcp::Engine, at: "/mcp"
end
