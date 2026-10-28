# 04. Token-efficient API responses

## Why

The review skill reads screen history into a model's context. Default JSON
repeats every key on every row and dumps whole accessibility trees, so most
of the tokens go on structure rather than content.

## State in 0.4.15

Missing. `crates/screenpipe-engine/src/routes/search.rs` has no `format` or
`fields` parameter. Responses are typed JSON only.

## Behaviour wanted

### Columnar output

`/search`, `/elements` and `/frames/:id/elements` accept:

- `format=csv` or `format=tsv`, returning one header row, then one row per
  result;
- `fields=a,b,c`, returning only those columns in that order. An unknown
  field is a `400` that lists the valid fields.

Without `format`, the response is byte-for-byte the current JSON. Nested
values are flattened with dotted names such as `content.app_name`. Text
cells are escaped according to RFC 4180 for CSV, and tabs and newlines are
escaped for TSV. Pagination metadata goes in response headers, so the body
stays a plain table.

Upstream reports roughly 70% fewer tokens on list-shaped results.

### Outline output

`/elements` and `/frames/:id/elements` accept `format=outline` (alias
`tree`). The response is an indented plain-text view of the accessibility
tree that:

- keeps only nodes that carry text;
- collapses runs of identical siblings to one line with `×N`;
- puts frame context (app, window, URL, timestamp) in a single header;
- flags off-screen elements inline.

Upstream reports roughly 75 to 80% fewer tokens than the default JSON.

### MCP

The MCP element tools (`search-elements` and `get-frame-elements`) default
to `format=outline`. `search-content` gains an optional `format` and
`fields`.

## Done when

- Golden tests: for a fixed fixture database, each format and field set
  produces a checked-in expected output.
- Requests without the new parameters return exactly what 0.4.15 returned
  for the same fixture.
- On a real day of your own data, the token count (with the tokenizer your
  review model uses) for a typical review query falls by at least 60% for
  CSV and at least 70% for outline, against JSON.
