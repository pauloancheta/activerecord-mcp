# frozen_string_literal: true

require "rails/generators"

module RailsMcp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a rails-mcp initializer in config/initializers"

      def copy_initializer
        template "initializer.rb", "config/initializers/rails_mcp.rb"
      end
    end
  end
end
