# Querying

rails-mcp exposes five built-in tools. All queries go through hash conditions validated against actual column names — no raw SQL is accepted at any layer.

## Default fields

Every query tool returns only `id`, `created_at`, and `updated_at` by default. Pass a `fields` array to retrieve additional columns. This default can be changed via [`configuration`](configuration.md).

## Tools

### `list_models`

Lists all accessible ActiveRecord model names.

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "list_models",
    "arguments": {}
  },
  "id": 1
}
```

Response:
```json
["Order", "Post", "User"]
```

---

### `describe_model`

Returns columns (name, type, nullability, default), and associations for a model.

```json
{
  "name": "describe_model",
  "arguments": { "model": "User" }
}
```

Response:
```json
{
  "model": "User",
  "table": "users",
  "primary_key": "id",
  "columns": [
    { "name": "id",         "type": "integer", "null": false, "default": null },
    { "name": "email",      "type": "string",  "null": false, "default": null },
    { "name": "created_at", "type": "datetime","null": false, "default": null }
  ],
  "associations": [
    { "name": "posts", "macro": "has_many", "class_name": "Post" }
  ]
}
```

Denied columns are excluded from the output — they do not appear in `columns` at all.

---

### `query_records`

Queries records with hash conditions.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `model` | string | yes | Model class name, e.g. `"User"` |
| `conditions` | object | no | Column/value pairs for WHERE clause |
| `fields` | array of strings | no | Columns to return (defaults to id + timestamps) |
| `limit` | integer | no | Max records; silently capped at `max_limit` (default 100) |
| `offset` | integer | no | Records to skip; raises an error if it exceeds `max_offset` (default 10,000) |
| `order` | string | no | `"column_name ASC"` or `"column_name DESC"` |

```json
{
  "name": "query_records",
  "arguments": {
    "model": "User",
    "conditions": { "active": true },
    "fields": ["id", "name", "email"],
    "limit": 25,
    "offset": 0,
    "order": "created_at DESC"
  }
}
```

Response:
```json
[
  { "id": 1, "name": "Alice", "email": "alice@example.com" },
  { "id": 2, "name": "Bob",   "email": "bob@example.com" }
]
```

**Condition values** must be scalars (`string`, `integer`, `float`, `boolean`, `null`) or arrays of scalars (for SQL `IN`). Hash values are rejected to prevent operator injection.

```json
{ "conditions": { "status": ["active", "pending"] } }
```

---

### `find_record`

Finds a single record by primary key.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `model` | string | yes | Model class name |
| `id` | integer | yes | Primary key value |
| `fields` | array of strings | no | Columns to return |

```json
{
  "name": "find_record",
  "arguments": {
    "model": "User",
    "id": 42,
    "fields": ["name", "email", "created_at"]
  }
}
```

Response:
```json
{ "name": "Alice", "email": "alice@example.com", "created_at": "2024-01-15T10:00:00.000Z" }
```

Returns an error if the record does not exist.

---

### `count_records`

Counts records matching hash conditions.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `model` | string | yes | Model class name |
| `conditions` | object | no | Column/value pairs for WHERE clause |

```json
{
  "name": "count_records",
  "arguments": {
    "model": "Order",
    "conditions": { "status": "pending" }
  }
}
```

Response:
```json
{ "count": 17 }
```

---

## Security model

- **Column validation** — every column in `fields`, `conditions`, and `order` is checked against the allowed column list before the query runs. Unknown or denied columns raise an error.
- **Value validation** — condition values must be scalars or arrays of scalars. Hash values (which could trigger Rails 7.1+ predicate operators) are rejected.
- **Quoted identifiers** — `SELECT` columns are quoted via Arel; `ORDER BY` columns are quoted via `quote_column_name`. No raw string interpolation reaches the DB.
- **Output strip** — denied columns are stripped from serialized output after the query, independent of the pre-query validation.
- **No raw SQL** — there is no `sql:` or `raw:` parameter on any tool.
