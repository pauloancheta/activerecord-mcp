# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record
  resource_owner_authenticator { nil }
  default_scopes
  pkce_code_challenge_methods %w[S256]
  access_token_expires_in 2.hours
  skip_authorization { true }
end
