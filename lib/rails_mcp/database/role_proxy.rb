# frozen_string_literal: true

module RailsMcp
  module Database
    module RoleProxy
      def self.with_role(&block)
        ActiveRecord::Base.connected_to(role: RailsMcp.configuration.database_role, &block)
      end
    end
  end
end
