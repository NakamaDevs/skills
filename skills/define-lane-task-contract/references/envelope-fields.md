# Envelope fields

A lane task envelope is one JSON object. `scripts/lane_task_envelope.exs`
rejects any field not listed here and rejects a missing required field. Every
field is required except `live_smoke`, which is required exactly when
`affects_runtime` is `true` and forbidden otherwise (see
[Runtime smoke check](#runtime-smoke-check)).

## Identity and delegation

| Field | Type | Rule |
| --- | --- | --- |
| `role` | string | Must equal `"lane"`. This contract only covers a task delegated from a coordinator to one lane. |
| `owner` | string | Non-empty. The human or team accountable for the work. |
| `issue` | string | Matches `ORG-123` (`^[A-Z]{2,10}-[0-9]+$`). |
| `branch` | string | Starts with an accepted Conventional Commit type: `feature`, `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, `perf`, `style`, or `revert`, followed by `/` and a lowercase slug. Matches the branch-prefix rule already enforced by `scripts/nakama_governance.py`. |
| `worktree` | string | Absolute path to the isolated git worktree the lane must work in. |
| `parent_task` | string | Non-empty identifier for the coordinator task that created this envelope. |
| `parent_agent` | string | Matches the herdr agent name pattern `^[a-z][a-z0-9_-]{0,31}$`. This is the exact `herdr agent prompt` target for [`notify_parent.exs`](../scripts/notify_parent.exs); see [notify-parent-protocol.md](notify-parent-protocol.md). |
| `result_path` | string | A relative path (no leading `/`, no `..` segment) inside the worktree where the lane must write its result. |
| `notification_state` | string | One of `pending`, `sent`, `acknowledged`. A new envelope starts `pending`. |

## Bounded execution shape

| Field | Type | Rule |
| --- | --- | --- |
| `graph_depth` | integer | `0` through `2`. Counts coordinator-to-lane nesting; a lane may not spawn a sub-graph more than two levels deep. |
| `panes` | integer | `1` through `4`. The maximum number of Herdr panes this lane task may use at once. |
| `delegation_allowed` | boolean | Must be `false` when `graph_depth` is `2` — a task at the depth cap is a leaf and cannot delegate further without breaking that cap. When `false`, no command anywhere in the envelope (`red_tests`, `green_commands`, `repository_gates`, `post_integration_tests`, `live_smoke`) may invoke `herdr agent start` or `herdr agent prompt`; see [command-safety.md](command-safety.md#leaf-delegation). |
| `writers` | array of `{"path", "owner"}` | Each `path` is canonicalized by resolving it (`Path.expand/2`) against `worktree`: trailing slashes, embedded `.` segments, and resolvable `..` segments are all removed the same way. A path that resolves outside `worktree` — `../../etc/passwd`, `skills/../../../../etc/passwd`, `/etc/passwd` — is rejected as an escape, not silently clamped. No two entries may resolve to the same canonical path or to an ancestor/descendant of each other — `skills/foo` and `skills/foo/bar` overlap just as much as two entries both naming `skills/foo`, and `skills/./foo` and `skills/other/../foo` are the same path as `skills/foo` for this comparison. This lexical check cannot see a symlink; see `resolve_writer_paths/1` below for the live check that can. |

`LaneTaskEnvelope.resolve_writer_paths/1` is the live counterpart to the
lexical `writers` check above, the same way `resolve_integration_head/1` is
the live counterpart to `integration`. `Path.expand/2` is purely lexical
string algebra — it never touches the filesystem — so a `writers[].path`
that is lexically inside `worktree` can still point outside it through a
symlink whose target the lexical check never reads (an in-worktree symlink
to `/etc`, for example). `resolve_writer_paths/1` resolves every symlink
along the path components that actually exist on disk (a component a lane
has not created yet cannot have its symlinks resolved, so the remainder is
still joined lexically) and rejects a path whose real target falls outside
`worktree`. The normal documented CLI runs this immediately after
`resolve_integration_head/1` succeeds; code calling `validate/1` directly
gets none of this for free either.

## Required initial state

`required_initial_state` is an object with exactly three fields:

- `branch` (string) — must equal the envelope's own `branch`.
- `clean_worktree` (boolean) — must be `true`.
- `base_ref` (string) — non-empty; the ref the branch was cut from.

A lane must confirm this state before doing any work, not assume it.

## Integration and branch lifecycle

`integration` is an object with exactly three fields:

- `target` (string) — non-empty; the branch this work integrates into (for
  example `"main"`).
- `base_head` (string) — a full 40-character lowercase commit sha; the exact
  commit the branch was based on (its fork point from `target`).
- `branch_lifecycle` (string) — must equal `"short-lived"`. A lane branch is
  merged or discarded quickly; it does not become a long-lived parallel
  trunk.

Before drafting the next envelope for the same issue, confirm
`required_initial_state.base_ref` and `integration.base_head` reflect the
current head of `integration.target`, not a head that predates an earlier
integration. Next work starts from updated trunk, not from a branch that
forked before the last merge.

`LaneTaskEnvelope.validate/1` only checks the *shape* of `integration`
above — it never touches the filesystem or runs git, by design (see
[command-safety.md](command-safety.md)'s note on `validate/1` staying pure).
Whether `base_head` actually exists and actually equals the merge base of
`branch` and `target` is a separate, live check:
`LaneTaskEnvelope.resolve_integration_head/1` resolves `target` and
`base_head` in the envelope's own declared `worktree` by shelling out to
`git -C <worktree> cat-file -e` and `git -C <worktree> merge-base`. The
normal documented CLI (`elixir lane_task_envelope.exs <envelope.json>`)
already runs this check immediately after `validate/1` succeeds — an
unknown or stale `base_head` fails that CLI run with a clear message. Code
calling `LaneTaskEnvelope.validate/1` directly, without going through the
CLI, gets none of this for free and must call
`resolve_integration_head/1` itself before trusting `integration.base_head`.

## Runtime smoke check

`affects_runtime` (boolean) declares whether this task changes behavior a
running instance of the software exhibits, as opposed to validators, docs, or
other build-time-only artifacts.

- When `affects_runtime` is `true`, `live_smoke` is required, and it proves
  the *running* software, not a unit-test double. A red test or green
  command proves code behaves correctly in isolation; `live_smoke` proves
  the deployed or locally running instance actually does the thing.
  `live_smoke` has exactly one shape — `endpoint` — required alongside
  `timeout_ms`:
  - `endpoint` — a declared health-check contract:
    `{"url": "<non-empty string>", "expect_status": <100-599>}`.

  `live_smoke.command` does not exist. An earlier revision allowed a
  command argv, checked against a positive allow-list of known
  observability binaries (`curl`, `grpc_health_probe`, `nc`, `ncat`,
  `wget`) after the same wrapper unwrap used elsewhere in this contract.
  That allow-list still trusted the *string* a lane declared as the
  executable: a relative path (`./tools/curl`), an absolute path outside
  any trusted location (`/tmp/curl` — world-writable on most systems), or
  an env-wrapped `PATH` override (`PATH=./tools`) can each make an
  allow-listed *name* resolve to an attacker-planted binary, all while the
  argv itself stays perfectly well-formed. Closing that hole would require
  resolving the declared executable through an explicit trusted-path
  policy — never the process `PATH`, never a bare basename comparison —
  and none of those five binaries has one absolute path that is the same
  across this project's Linux, macOS, and Windows runners, so no such
  policy can be both trustworthy and portable. `live_smoke.endpoint`
  carries no executable at all, so it has no version of this problem;
  every prior `live_smoke.command` use case is expected to be expressible
  as an HTTP status check instead.
- When `affects_runtime` is `false`, `live_smoke` must be absent.

## Feature-to-test inventory

`feature_test_inventory_path` — a non-empty relative path (no leading `/`, no
`..` segment) to the durable document mapping this contract's enforceable
features to the tests that cover them. See
[`references/feature-test-inventory.md`](feature-test-inventory.md) for the
inventory this skill maintains about itself, and keep any inventory this
field points to current in the same change that adds or removes a rule.

## Inputs, outputs, and goal

- `inputs` — non-empty array of non-empty strings (files, docs, or prior
  artifacts the lane may read).
- `outputs` — non-empty array of non-empty strings (paths the lane is
  expected to create or change).
- `observable_goal` — a non-empty, single-line string. State the one
  observable condition that proves the task is done. Do not describe
  implementation steps here; describe what an outside observer can check.

## Test-first commands

`red_tests`, `green_commands`, `repository_gates`, and
`post_integration_tests` are each a non-empty array of command objects:

```json
{"command": ["elixir", "test/lane_task_envelope_test.exs"], "timeout_ms": 30000}
```

- `red_tests` — the commands that must fail before implementation exists.
- `green_commands` — the commands that must pass after implementation.
- `repository_gates` — the repository-wide checks the lane must also pass
  (for example `mise run verify:quick`). Each entry additionally requires
  `"when": "handoff"`: a repository gate runs once, at handoff, not on every
  intermediate commit.
- `post_integration_tests` — the integration tests affected by this change
  that must be run again *after* the branch integrates into
  `integration.target`, against the resulting trunk.

See [command-safety.md](command-safety.md) for the rules `command` and
`timeout_ms` must satisfy.

## Deletions

`deletion_decisions` — an array, possibly empty, of `{"target",
"replacement_decision"}` objects. Behavior or a test may be deleted, but
never silently: every deletion this task makes needs an entry naming what
was deleted (`target`) and the explicit decision covering what replaces it
(`replacement_decision`). An empty array asserts the task deletes nothing.

## Stop conditions and protected actions

- `stop_conditions` — non-empty array of non-empty strings. Each names a
  condition under which the lane must stop and hand control back rather than
  continue. When the requested scope is unknown or ambiguous, that is a stop
  condition, not a judgment call: the lane asks the parent agent before
  editing.
- `protected_actions` — non-empty array, no duplicates, drawn only from:
  `credential-changes`, `deploy`, `force-push`, `merge`,
  `production-effects`, `public-ingress`, `push`, `release`. These mirror the
  `deny:` vocabulary already used in
  [`bootstrap-symphony-workflow`](../../bootstrap-symphony-workflow/references/safe-workflow.md).
  An envelope names every action forbidden to the lane; it does not grant any
  action by omission.

## Binding an envelope to its notifications

`LaneTaskEnvelope.digest/1` computes a stable sha256 digest of the whole
envelope. It is not a field in the envelope itself; `notify_parent.exs`
computes it from the task and includes it as `envelope_digest` in every
event it sends, so the coordinator can verify a result or blocker event was
built from the exact envelope it issued rather than a modified or
substituted one. See [notify-parent-protocol.md](notify-parent-protocol.md).

## Agent and the Claude auto contract

`agent` is an object with required `kind` and `mode` (both non-empty
strings). When `kind` is `"claude"` and `mode` is `"auto"`, five more fields
are required (`model`, `effort`, `routing_reason`, `permission_mode`,
`startup_verification`). See
[claude-auto-contract.md](claude-auto-contract.md).

When `kind` is `"codex"` and `mode` is `"auto"`, four fields are required:

- `agent.model` — one of `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`.
- `agent.effort` — one of `none`, `low`, `medium`, `high`, `xhigh`, `max`.
  The Claude-only value `auto` is rejected.
- `agent.routing_reason` — string, non-empty after trimming whitespace,
  stating why this model and effort were chosen and what measured evidence
  (if any) supports it.
- `agent.command` — see below.

[model-routing.md](model-routing.md) is the policy behind the model and
effort choices for both providers; model and effort are separate choices,
and Claude effort sets are model-specific (`claude-haiku-4-5-20251001`
takes only the sentinel `not-supported`).
In any `mode` other than `"auto"`, none of `model`, `effort`, or
`routing_reason` is required for either provider.

`agent.command` is the argv (same shape and safety rules as
[Test-first commands](#test-first-commands)) that starts this automated
Codex role. Three rules apply to it, none a substitute for another:

- It must include `-c check_for_update_on_startup=false`; see
  [command-safety.md](command-safety.md#every-codex-startup-command-disables-the-interactive-update-prompt).
- Its resolved executable must actually be `codex` — the update-prompt
  flag alone does not prove that. `["herdr", "agent", "start", "child",
  "-c", "check_for_update_on_startup=false"]` carries the flag and stays
  argv-safe, but starts `herdr`, not `codex`, and is rejected with
  "`agent.command` must resolve to the codex executable" regardless.
- It is scanned by the same leaf-delegation check as every other command
  field (`red_tests`, `green_commands`, `repository_gates`,
  `post_integration_tests`): when `delegation_allowed` is `false`, an
  `agent.command` that starts `herdr agent start`/`herdr agent prompt`
  fails that check too, on top of failing the executable check above.
