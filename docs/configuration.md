# Configuration

Configure rails-mcp in an initializer. All settings have defaults — you only need to set what you want to change.

```ruby
# config/initializers/rails_mcp.rb
RailsMcp.configure do |config|
  config.database_role  = :reading
  config.default_fields = [:id, :created_at, :updated_at]
  config.allowed_models = []
  config.denied_models  = []
  config.denied_columns = []
  config.max_limit      = 100
  config.schema_file    = nil
end
```

## Options

### `database_role`

**Default:** `:reading`

The ActiveRecord role passed to `connected_to(role:)` for every query. Use any role defined in your `database.yml`.

```ruby
config.database_role = :reading
```

Requires Rails 6.1+. If your app uses a single database without named roles, set this to `:writing` (the default primary role in Rails).

---

### `default_fields`

**Default:** `[:id, :created_at, :updated_at]`

Columns returned when a tool call includes no `fields` argument. Also automatically included when a `schema_file` is configured, even if the file omits them.

```ruby
config.default_fields = [:id, :name, :created_at, :updated_at]
```

---

### `allowed_models`

**Default:** `[]` (empty — all models accessible)

When non-empty, only the listed model names are accessible. Any other model name returns an error.

```ruby
config.allowed_models = %w[User Post Order]
```

Ignored when `schema_file` is set — the schema file's top-level keys serve as the allowlist.

---

### `denied_models`

**Default:** `[]` (none denied)

Model names that are never accessible, regardless of `allowed_models`.

```ruby
config.denied_models = %w[AdminUser AuditLog]
```

Ignored when `schema_file` is set.

---

### `denied_columns`

**Default:** `[]` (none denied)

An array of exact strings and/or regexes. Any matching column is completely invisible across all models and all tools — it cannot appear in query results, conditions, fields, or order clauses.

```ruby
config.denied_columns = [
  "password_digest",
  "encrypted_password",
  /token/i,
  /secret/i,
  /api_key/i
]
```

`denied_columns` is applied after all other column resolution (schema file, `default_fields`). It always wins — a column listed in a schema file but matching a denied pattern is still denied.

See [Advanced Usage → Explicit column deny](advanced.md#explicit-column-deny) for details.

---

### `max_limit`

**Default:** `100`

Maximum number of records any `query_records` call can return. Client-supplied `limit` values are capped to this. Nil or zero limits also resolve to this value.

```ruby
config.max_limit = 50
```

---

### `schema_file`

**Default:** `nil`

Path to a YAML file that defines exactly which models and columns the MCP can access. When set, it replaces `allowed_models` / `denied_models` with the file's model list.

```ruby
config.schema_file = Rails.root.join("config/rails_mcp.yml")
```

See [Advanced Usage → YAML model allowlist](advanced.md#yaml-model-allowlist) for the file format.
