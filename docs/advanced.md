# Advanced Usage

## YAML model allowlist

For production deployments you typically want an explicit, auditable list of which models and columns the MCP can expose. The `schema_file` option points to a YAML file that defines this.

### Format

```yaml
# config/rails_mcp.yml
User:
  - name
  - email
  - active
  - created_at

Post:
  - title
  - body
  - published_at
  - created_at
```

Each key is a model name; each value is the list of columns that can appear in `fields`, `conditions`, and `order`. Model names must match your AR class name exactly (including namespace, e.g. `Admin::User`).

You do **not** need to include `id`, `created_at`, or `updated_at` — they are auto-included from `default_fields` regardless of what the file lists. If you want to exclude them, override `default_fields` in the initializer.

### Behaviour when set

- Only models listed in the file are accessible. Any other model name returns an error.
- Each model's columns are restricted to the listed set plus `default_fields`.
- `allowed_models` and `denied_models` config options are ignored — the file is the authoritative list.
- `denied_columns` still applies on top of the file — a column listed in the YAML but matching a denied pattern is still denied.

### Referencing it in the initializer

```ruby
# config/initializers/rails_mcp.rb
RailsMcp.configure do |config|
  config.schema_file = Rails.root.join("config/rails_mcp.yml")
end
```

---

## Explicit column deny

`denied_columns` lets you block specific columns across all models regardless of any other configuration. It is the right tool for sensitive columns that should never be accessible — password hashes, tokens, secrets, PII you want excluded from AI context.

### Strings and regexes

```ruby
config.denied_columns = [
  "password_digest",           # exact match
  "encrypted_password",        # exact match
  /token/i,                    # case-insensitive regex — matches reset_token, api_token, etc.
  /secret/i,                   # matches client_secret, secret_key, etc.
  /api_key/i,
  /ssn/i,
  /credit_card/i
]
```

### What "denied" means

A denied column is invisible at every layer:

- **`describe_model`** — the column does not appear in the schema output
- **`query_records` / `find_record`** — requesting the column in `fields` raises an error
- **`query_records` / `count_records`** — using the column in `conditions` raises an error; this closes the count-oracle attack where an attacker could confirm a hash value by filtering on it and checking the count
- **`query_records`** — using the column in `order` raises an error
- **Output strip** — denied columns are removed from serialized results after the query, as a second independent safety net

### Interaction with schema_file

`denied_columns` always wins. If your YAML file lists `email` and you also have `/email/i` in `denied_columns`, the column is denied.

```ruby
# config/rails_mcp.yml lists email
# config/initializers/rails_mcp.rb denies it
config.schema_file    = Rails.root.join("config/rails_mcp.yml")
config.denied_columns = [/email/i]
# result: email is inaccessible despite being in the YAML
```

---

## Custom tools

Register your own MCP tools alongside the built-ins. Tools must be registered **before the first request** because the MCP server is built at boot time. An initializer is the right place.

```ruby
# config/initializers/rails_mcp.rb
RailsMcp::Server.tool("business_summary") do
  description "Return a revenue summary for a given date"

  parameter :date,     type: :string,  description: "ISO 8601 date (e.g. 2024-01-15)", required: true
  parameter :currency, type: :string,  description: "Currency code, defaults to USD"

  call do |params, _server_context|
    date   = Date.parse(params[:date])
    orders = Order.where(created_at: date.all_day)
    {
      date:     date.iso8601,
      count:    orders.count,
      total:    orders.sum(:amount_cents),
      currency: params[:currency] || "USD"
    }
  end
end
```

### DSL reference

| Method | Arguments | Description |
|--------|-----------|-------------|
| `description` | string | Human-readable description shown in `tools/list` |
| `parameter` | `name, type:, description: nil, required: false` | Declares an input parameter |
| `call` | block `\|params, server_context\|` | The tool's implementation; return value is JSON-serialized |

Supported `type` values: `:string`, `:integer`, `:number`, `:boolean`, `:array`, `:object`.

### Accessing `server_context`

`server_context` contains request-scoped data set by the middleware layer. The Doorkeeper access token is available as:

```ruby
call do |params, server_context|
  token = server_context["rails_mcp.access_token"]
  user  = token&.resource_owner
  # ...
end
```

### Registration timing

The MCP server is memoized on first use. Registering a tool after the server has been built has no effect. All `RailsMcp::Server.tool` calls must complete before the first request reaches the engine. Rails initializers run before the server is built, so they are the correct place.
