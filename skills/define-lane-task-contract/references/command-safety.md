# Command safety

`red_tests`, `green_commands`, and `repository_gates` each hold command
objects. `scripts/lane_task_envelope.exs` enforces every rule below on every
command object in every one of those three fields.

## `command` must be an argv list

```json
{"command": ["mise", "run", "verify:quick"], "timeout_ms": 60000}
```

`command` must be a JSON array of strings, never a single string. A single
string is a shell command line, and this contract never runs one: there is no
shell to interpret it, no quoting to get wrong, and no injection surface. A
string value fails validation with "must be an argv list, not a shell
string".

## Every argv token is checked against an allow-list

Each token in `command` must fully match `^[A-Za-z0-9_./:=,@-]+$`. This is an
allow-list, not a deny-list: a token is rejected unless every character in it
is a letter, digit, or one of `_ . / : = , @ -`. That rejects shell
metacharacters (`; | & $ \` > < ( ) { } * ? ~ # !`, quotes, and whitespace)
without needing to enumerate them, and it rejects a token created by
concatenating two commands (for example `"test && rm -rf /"`).

## No manual database lifecycle command

A command's first argv token (its basename, case-insensitive) must not be one
of: `pg_ctl`, `pg_ctlcluster`, `initdb`, `createdb`, `dropdb`, `createuser`,
`dropuser`, `mysqladmin`, `mysqld`, `mongod`, `mongosh`, `redis-server`,
`redis-cli`, `sqlite3`. A lane task drives the database only through the
repository's own tasks (`mix ecto.*`, `mise run ...`), never by starting,
stopping, creating, or dropping a database directly. Direct lifecycle control
of a database is exactly the kind of effect this contract keeps out of an
unattended lane.

## No wait over 60000 ms

`timeout_ms` must be an integer from `1` through `60000`. An unattended lane
task must never block indefinitely; every command carries its own bound, and
that bound cannot exceed one minute. A missing or out-of-range `timeout_ms`
fails validation.

## Related bounds outside `command`

Two more bounds apply to the envelope as a whole, not to any one command:

- `graph_depth` must not exceed `2` (coordinator → lane → grandchild is the
  deepest allowed graph).
- `panes` must not exceed `4`.

See [envelope-fields.md](envelope-fields.md) for both.
