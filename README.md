# rails-mcp

A Rails Engine that adds an [MCP (Model Context Protocol)](https://modelcontextprotocol.io) server to your app. Built on the [official MCP Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk), it exposes safe, role-aware ActiveRecord query tools over **Streamable HTTP** — no SSE, no standalone process, no extra memory footprint.

Because it mounts as a Rails Engine, MCP requests share Puma's thread pool and ActiveRecord connection pool with the rest of your app.

## Table of contents

- [Installation](#installation)
- [Basic setup](#basic-setup)
- [Quick example](#quick-example)
- [Documentation](#documentation)
- [Why not fast-mcp?](#why-not-fast-mcp)

## Installation

Add to your Gemfile:

```ruby
gem "rails-mcp"
gem "doorkeeper"
```

```bash
bundle install
bin/rails generate doorkeeper:install
bin/rails generate doorkeeper:migration
bin/rails db:migrate
```

## Basic setup

**1. Configure Doorkeeper** (`config/initializers/doorkeeper.rb`):

```ruby
Doorkeeper.configure do
  orm :active_record
  pkce_code_challenge_methods %w[S256]

  resource_owner_authenticator do
    current_user || redirect_to(new_user_session_url)
  end
end
```

**2. Mount the engine** (`config/routes.rb`):

```ruby
Rails.application.routes.draw do
  use_doorkeeper
  mount RailsMcp::Engine, at: "/mcp"
end
```

**3. Restrict which models are accessible** (`config/initializers/rails_mcp.rb`):

```ruby
RailsMcp.configure do |config|
  config.allowed_models = %w[User Post Order]
  config.denied_columns = ["password_digest", /token/i, /secret/i]
end
```

That's it — the five built-in query tools are live at `/mcp`.

## Quick example

```bash
# Get a Bearer token (see docs/authentication.md)
TOKEN="eyJhbGc..."

# List accessible models
curl -X POST https://your-app.com/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"list_models","arguments":{}},"id":1}'

# Query records
curl -X POST https://your-app.com/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "query_records",
      "arguments": {
        "model": "User",
        "conditions": { "active": true },
        "fields": ["id", "name", "email"],
        "limit": 10
      }
    },
    "id": 2
  }'
```

## Documentation

| Topic | Description |
|-------|-------------|
| [Authentication](docs/authentication.md) | OAuth 2.1 + PKCE setup, Bearer tokens, discovery endpoint |
| [Querying](docs/querying.md) | All five built-in tools with full argument reference |
| [Configuration](docs/configuration.md) | All config options with defaults and explanations |
| [Advanced usage](docs/advanced.md) | YAML model allowlist, explicit column deny, custom tools DSL |

## Why not fast-mcp?

fast-mcp uses SSE transport, which holds a Puma thread open for the lifetime of each client connection. With 5 Puma threads and 5 MCP clients connected, your app is saturated. SSE was [deprecated in the MCP spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports) in March 2025 in favour of Streamable HTTP, which uses normal short-lived POST requests.

## Development

```bash
bundle install
bundle exec rake test
```

Bug reports and pull requests welcome at https://github.com/pauloancheta/rails-mcp.
