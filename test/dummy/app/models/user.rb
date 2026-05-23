# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :posts
  validates :name, :email, presence: true
end
