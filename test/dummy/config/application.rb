# frozen_string_literal: true

require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_dispatch/railtie"
require "doorkeeper"
require "rails_mcp"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.load_defaults 7.0
    config.eager_load = false
    config.logger = Logger.new(nil)
    config.active_record.sqlite3_adapter_strict_strings_by_default = false
  end
end
