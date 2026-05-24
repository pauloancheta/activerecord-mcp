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

---

## Value-based access control

The built-in tools control *which models* and *which columns* are visible. Sometimes you need finer control: restricting which **values** a caller can query, or scoping queries to a fixed subset of rows. The custom tool DSL is the right tool for both cases.

### Allowlisted key access

A common pattern is a `settings` table with a `key` column and a `value` column. The built-in tools would let any authenticated caller query any key — including secrets stored alongside innocuous settings. A custom tool enforces an explicit allowlist:

```ruby
RailsMcp::Server.tool("get_setting") do
  description "Return a whitelisted application setting"

  parameter :key, type: :string, required: true,
                  description: "Setting key. Allowed: theme, locale, timezone"

  call do |params, _server_context|
    allowed = %w[theme locale timezone date_format]
    raise "Setting '#{params[:key]}' is not accessible" unless allowed.include?(params[:key])

    row = Setting.find_by(key: params[:key])
    raise "Setting not found" unless row

    { key: row.key, value: row.value }
  end
end
```

The built-in `query_records` tool can be disabled for `Setting` entirely by adding it to `denied_models`:

```ruby
config.denied_models = ["Setting"]
```

Now the only way to read settings is through `get_setting`, and it only returns keys on the allowlist.

### Fixed-scope row access

When a column like `role` determines visibility — for example, MCP callers should only ever see customers, never admins — hard-code the scope in a custom tool rather than relying on the caller to pass the right condition:

```ruby
RailsMcp::Server.tool("list_customers") do
  description "List users with role=customer. Admin and internal users are never returned."

  parameter :limit, type: :integer, description: "Max records (default 20)"

  call do |params, _server_context|
    limit = [params[:limit].to_i.nonzero? || 20, 100].min
    User.where(role: "customer")
        .select(:id, :email, :name, :created_at)
        .limit(limit)
        .map { |u| u.slice("id", "email", "name", "created_at") }
  end
end
```

Combined with `denied_columns = [/role/i]`, the `role` column is invisible in all built-in tool output *and* the custom tool never exposes non-customer rows.

