# frozen_string_literal: true

module RailsMcp
  class Configuration
    attr_accessor :database_role,
                  :default_fields,
                  :allowed_models,
                  :denied_models,
                  :max_limit

    def initialize
      @database_role  = :reading
      @default_fields = %i[id created_at updated_at]
      @allowed_models = []
      @denied_models  = []
      @max_limit      = 100
    end
  end
end
