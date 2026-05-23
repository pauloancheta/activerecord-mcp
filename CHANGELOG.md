# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [0.1.0] - 2026-05-23

### Added

- Five built-in ActiveRecord query tools: `list_models`, `describe_model`, `query_records`, `find_record`, `count_records`
- Read-only by default via `database_role` config (uses Rails' `connected_to`)
- `schema_file` option — YAML file defining per-model column allowlists; `id`, `created_at`, `updated_at` auto-included
- `denied_columns` config accepting exact strings and regexes; applied as a final layer over all other config
- Two-pass security model: denied columns blocked before query (validation) and stripped after (output sanitisation)
- `ColumnPolicy` as the single source of truth for allowed columns across all query paths
- Hash condition value validation — rejects Hash values to block Rails 7.1+ predicate operators
- Quoted SELECT via Arel — column identifiers are always fully qualified and DB-quoted
- `max_limit` config (default 100) — silently caps `query_records` limit
- `max_offset` config (default 10,000) — raises an error on deep pagination attempts
- OAuth 2.1 + PKCE authentication via Doorkeeper; `TokenValidator` Rack middleware
- `scope` config (default `"mcp"`) — tokens without the required scope are rejected with `403 insufficient_scope`
- `GET /.well-known/oauth-authorization-server` — public OAuth discovery endpoint
- Custom tool DSL — `RailsMcp::Server.tool("name") { ... }` registers tools before first request
- `bin/rails generate rails_mcp:install` — scaffolds a documented initializer with all options commented out
- Streamable HTTP transport via the official MCP Ruby SDK (`mcp` gem); no SSE, no standalone process
- Mounts as a Rails Engine — shares Puma thread pool and ActiveRecord connection pool
- Full documentation in `docs/`: authentication, querying, configuration, advanced usage
