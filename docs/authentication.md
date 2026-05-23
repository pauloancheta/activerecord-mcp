# Authentication

rails-mcp uses [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper) for OAuth 2.1 server-side authentication with PKCE. Every request to the MCP endpoint requires a valid Bearer token.

## How it works

A Rack middleware (`RailsMcp::Auth::TokenValidator`) sits in front of the MCP transport. It validates the Bearer token against Doorkeeper before the request ever reaches the JSON-RPC layer. Invalid, expired, or revoked tokens are rejected with a `401` response — no tool code runs.

Two paths bypass the middleware:
- `OPTIONS` requests (CORS preflight)
- `/.well-known/` paths (OAuth discovery — must be public)

## Setup

### 1. Install Doorkeeper

```ruby
# Gemfile
gem "doorkeeper"
gem "rails-mcp"
```

```bash
bin/rails generate doorkeeper:install
bin/rails generate doorkeeper:migration
bin/rails db:migrate
```

### 2. Configure Doorkeeper with PKCE

```ruby
# config/initializers/doorkeeper.rb
Doorkeeper.configure do
  orm :active_record

  # PKCE S256 is required — rails-mcp warns at boot if this is missing
  pkce_code_challenge_methods %w[S256]

  resource_owner_authenticator do
    current_user || redirect_to(new_user_session_url)
  end
end
```

rails-mcp logs a warning at boot if PKCE S256 is not enabled. It does not raise — Doorkeeper config is owned by the host app.

### 3. Add routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  use_doorkeeper
  mount RailsMcp::Engine, at: "/mcp"
end
```

## Making authenticated requests

Include the token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

Example:

```bash
curl -X POST https://your-app.com/mcp \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

## OAuth discovery

The endpoint `GET /mcp/.well-known/oauth-authorization-server` is public and returns standard OAuth 2.1 discovery metadata pointing to your Doorkeeper endpoints. MCP clients that support OAuth discovery can use this to auto-configure themselves.

```bash
curl https://your-app.com/mcp/.well-known/oauth-authorization-server
```

## Error responses

| Condition | Status | Body |
|-----------|--------|------|
| Missing `Authorization` header | `401` | `{"error":"missing_token"}` |
| Token not found | `401` | `{"error":"invalid_token"}` |
| Token revoked | `401` | `{"error":"invalid_token"}` |
| Token expired | `401` | `{"error":"invalid_token"}` |

All `401` responses include a `WWW-Authenticate: Bearer realm="rails-mcp"` header.

## Creating tokens (development)

```ruby
# bin/rails console
app   = Doorkeeper::Application.create!(
  name:          "my-mcp-client",
  redirect_uri:  "urn:ietf:wg:oauth:2.0:oob",
  confidential:  false,
  scopes:        ""
)
token = Doorkeeper::AccessToken.create!(application: app, expires_in: 7200)
puts token.token
```
