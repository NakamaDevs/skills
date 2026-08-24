# Envelope fields

A lane task envelope is one JSON object. `scripts/lane_task_envelope.exs`
rejects any field not listed here and rejects a missing required field. Every
field is required; none is optional.

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

## Inputs, outputs, and goal

- `inputs` — non-empty array of non-empty strings (files, docs, or prior
  artifacts the lane may read).
- `outputs` — non-empty array of non-empty strings (paths the lane is
  expected to create or change).
- `observable_goal` — a non-empty, single-line string. State the one
  observable condition that proves the task is done. Do not describe
  implementation steps here; describe what an outside observer can check.

## Test-first commands

`red_tests`, `green_commands`, and `repository_gates` are each a non-empty
array of command objects:

```json
{"command": ["elixir", "test/lane_task_envelope_test.exs"], "timeout_ms": 30000}
```

- `red_tests` — the commands that must fail before implementation exists.
- `green_commands` — the commands that must pass after implementation.
- `repository_gates` — the repository-wide checks the lane must also pass
  (for example `mise run verify:quick`).

See [command-safety.md](command-safety.md) for the rules `command` and
`timeout_ms` must satisfy.

## Stop conditions and protected actions

- `stop_conditions` — non-empty array of non-empty strings. Each names a
  condition under which the lane must stop and hand control back rather than
  continue.
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
