# Command safety

`red_tests`, `green_commands`, `repository_gates`, `post_integration_tests`,
and (when present) `live_smoke` each hold command objects.
`scripts/lane_task_envelope.exs` enforces every rule below on every command
object in every one of those fields.

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

Every argv token (its basename, case-insensitive) is checked — not only the
first — against: `pg_ctl`, `pg_ctlcluster`, `initdb`, `createdb`, `dropdb`,
`createuser`, `dropuser`, `mysqladmin`, `mysqld`, `mongod`, `mongosh`,
`redis-server`, `redis-cli`, `sqlite3`. A lane task drives the database only
through the repository's own tasks (`mix ecto.*`, `mise run ...`), never by
starting, stopping, creating, or dropping a database directly. Direct
lifecycle control of a database is exactly the kind of effect this contract
keeps out of an unattended lane.

Checking every token, not just the first, matters because `env`, `mise exec
--`, and a shell's `-c` form are all legitimate ways to run an *allowed*
command indirectly, and each could otherwise smuggle a denylisted one past a
first-token-only check:

```json
["env", "DATABASE_URL=postgres://...", "dropdb", "app_dev"]
["mise", "exec", "--", "dropdb", "app_dev"]
["sh", "-c", "dropdb"]
["bash", "-c", "dropdb"]
```

The validator resolves through `env` (skipping its flags and `NAME=VALUE`
assignments), `mise exec --`, and `sh -c`/`bash -c`/`zsh -c`/`dash
-c`/`ksh -c` to find the command a wrapper would actually run, and checks
that resolved command too. All four examples above are rejected.

## No leaf delegation to another herdr agent

When the envelope's `delegation_allowed` is `false`, no command anywhere in
the envelope (`red_tests`, `green_commands`, `repository_gates`,
`post_integration_tests`, `live_smoke`) may invoke `herdr agent start` or
`herdr agent prompt` — a leaf task does not spawn or instruct another agent.
This is enforced the same way as every other rule here: by inspecting the
declared argv command, never by anything Herdr itself enforces. See
[envelope-fields.md](envelope-fields.md#bounded-execution-shape) for when
`delegation_allowed` must be `false`.

This check resolves through the same `env`/`mise exec --`/shell-`-c` wrappers
as the database-lifecycle check above, and checks a path-qualified
executable's basename the same way — `["env", "HERDR_ENV=1", "herdr",
"agent", "start", "child"]`, `["mise", "exec", "--", "/usr/local/bin/herdr",
"agent", "prompt", "child", "go"]`, and `["/usr/local/bin/herdr", "agent",
"start", "child"]` are all rejected exactly like the bare `["herdr", "agent",
"start", "child"]` form.

## `live_smoke.command` is a positive allow-list, not a denylist

The observable-probe rule in
[envelope-fields.md](envelope-fields.md#runtime-smoke-check) resolves through
the same wrappers too, and checks the resolved executable's basename rather
than the literal command array — but the check itself is an allow-list
(`curl`, `grpc_health_probe`, `nc`, `ncat`, `wget`), not a denylist of known
non-probes. A denylist naming `true` and unit-test runners would still let
`echo`/`printf` through: both always succeed and print whatever text
they're given without observing anything running, so `["echo", "ok"]`,
`["/bin/echo", "ok"]`, `["env", "FOO=bar", "echo", "ok"]`, `["mise", "exec",
"--", "echo", "ok"]`, and the same forms for `printf` are all rejected —
along with `["true"]`, a unit-test runner, and every wrapped or
path-qualified variant of either — for the same reason: none of them is on
the allow-list, regardless of what it isn't. Use `live_smoke.endpoint`
instead of `command` when the check is simply an HTTP status probe; see
[envelope-fields.md](envelope-fields.md#runtime-smoke-check).

## No wait over 60000 ms

`timeout_ms` must be an integer from `1` through `60000`. An unattended lane
task must never block indefinitely; every command carries its own bound, and
that bound cannot exceed one minute. A missing or out-of-range `timeout_ms`
fails validation.

## `repository_gates` run once, at handoff

Every `repository_gates` entry additionally requires `"when": "handoff"`.
`red_tests` and `green_commands` are the tight per-change TDD loop and run as
often as that loop turns; a repository-wide gate such as `mise run
verify:quick` is comparatively expensive and is required only once, at
handoff, not re-run on every intermediate commit. `post_integration_tests`
carries no `when` field: it runs, by name, after trunk integration, never
before.

## Related bounds outside `command`

Two more bounds apply to the envelope as a whole, not to any one command:

- `graph_depth` must not exceed `2` (coordinator → lane → grandchild is the
  deepest allowed graph).
- `panes` must not exceed `4`.

See [envelope-fields.md](envelope-fields.md) for both.

## `validate/1` never runs a command or touches the filesystem

Every rule above is checked by reading the declared `command` array as data.
`LaneTaskEnvelope.validate/1` never executes anything it validates, and it
never touches the filesystem or the network — that is what keeps it fast,
deterministic, and safe to run against an untrusted envelope. Two functions
in this skill are the deliberate exceptions: `resolve_integration_head/1`
shells out to `git` (see
[envelope-fields.md](envelope-fields.md#integration-and-branch-lifecycle)),
and `resolve_writer_paths/1` reads symlinks on disk (see
[envelope-fields.md](envelope-fields.md#bounded-execution-shape)). Both stay
logically separate functions from `validate/1` — but `elixir
lane_task_envelope.exs <envelope.json>`, the normal documented CLI, runs all
three in order: `validate/1`, then `resolve_integration_head/1`, then
`resolve_writer_paths/1`, each gating the next. A plain CLI run proves the
schema, the live integration claim, and that no writer path escapes the
worktree through a symlink — not just the schema. Code that calls
`LaneTaskEnvelope.validate/1` directly (as a library, not through the CLI)
gets none of the two live checks for free — call them explicitly in that
case.

## The CLI takes exactly the operands it documents

`elixir lane_task_envelope.exs <envelope.json>` takes exactly one operand;
`elixir lane_task_result.exs <result.json> <task.json>` and `elixir
notify_parent.exs <task.json> <result.json>` each take exactly two, in the
order shown. Zero operands or more than the documented count print a usage
line to stderr and exit `2`, rather than silently taking the first argument
and ignoring the rest.
