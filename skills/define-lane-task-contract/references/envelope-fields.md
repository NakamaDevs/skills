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
| `writers` | array of `{"path", "owner"}` | No two entries may share the same `path`. Two owners writing the same path is the failure mode this field exists to catch. |

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

## Runtime smoke check

`affects_runtime` (boolean) declares whether this task changes behavior a
running instance of the software exhibits, as opposed to validators, docs, or
other build-time-only artifacts.

- When `affects_runtime` is `true`, `live_smoke` is required: a command
  object (same shape as [Test-first commands](#test-first-commands)) that
  observes the *running* software, not a unit test double. A red test or
  green command proves code behaves correctly in isolation; `live_smoke`
  proves the deployed or locally running instance actually does the thing.
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

## Agent and the Claude auto contract

`agent` is an object with required `kind` and `mode` (both non-empty
strings). When `kind` is `"claude"` and `mode` is `"auto"`, three more fields
are required. See [claude-auto-contract.md](claude-auto-contract.md).
