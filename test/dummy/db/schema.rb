# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table :users, force: true do |t|
    t.string  :name,   null: false
    t.string  :email,  null: false
    t.integer :age
    t.boolean :active, default: true
    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string     :title,   null: false
    t.text       :body
    t.references :user,    null: false, foreign_key: true
    t.timestamps
  end

  # Doorkeeper tables
  create_table :oauth_applications, force: true do |t|
    t.string  :name,          null: false
    t.string  :uid,           null: false
    t.string  :secret,        null: false, default: ""
    t.text    :redirect_uri,  null: false
    t.text    :scopes,        null: false, default: ""
    t.boolean :confidential,  null: false, default: true
    t.timestamps null: false
  end
  add_index :oauth_applications, :uid, unique: true

  create_table :oauth_access_grants, force: true do |t|
    t.references :resource_owner, null: false, index: true
    t.references :application,    null: false
    t.string     :token,          null: false
    t.integer    :expires_in,     null: false
    t.text       :redirect_uri,   null: false
    t.text       :scopes,         null: false, default: ""
    t.string     :code_challenge
    t.string     :code_challenge_method
    t.datetime   :revoked_at
    t.timestamps null: false
  end
  add_index :oauth_access_grants, :token, unique: true

  create_table :oauth_access_tokens, force: true do |t|
    t.references :resource_owner, index: true
    t.references :application
    t.text       :token,              null: false
    t.text       :refresh_token
    t.integer    :expires_in
    t.text       :scopes
    t.datetime   :revoked_at
    t.string     :previous_refresh_token, null: false, default: ""
    t.timestamps null: false
  end
  add_index :oauth_access_tokens, :token,         unique: true
  add_index :oauth_access_tokens, :refresh_token, unique: true, where: "(refresh_token IS NOT NULL)"
end
