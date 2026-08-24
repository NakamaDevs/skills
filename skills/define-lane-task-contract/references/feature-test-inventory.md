# Feature-to-test inventory

Every enforceable rule in this skill maps to at least one ExUnit test. Update
this table in the same change that adds, changes, or removes a rule; a rule
without a listed test is not a real rule. This is the file
`feature_test_inventory_path` in the example envelope points to.

## `LaneTaskEnvelope` (`scripts/lane_task_envelope.exs`)

| Feature | Test |
| --- | --- |
| Unknown top-level field rejected | `test/lane_task_envelope_test.exs` — "rejects an unsupported top-level field" |
| Every field required | `test/lane_task_envelope_test.exs` — "rejects a missing #{field}" (one per field) |
| `role` must be `"lane"` | "role must be lane" |
| `owner` non-empty | "owner must be a non-empty string" |
| `issue` matches `ORG-123` | "issue must match an ORG-123 issue key" |
| `branch` Conventional Commit prefix | "branch must start with an accepted Conventional Commit type prefix", "branch accepts every Conventional Commit type prefix" |
| `worktree` absolute path | "worktree must be an absolute path" |
| `parent_agent` herdr name pattern | "parent_agent must match the herdr agent name pattern" |
| `result_path` relative, no `..` | "result_path must be relative", "result_path must not traverse out of the worktree" |
| `notification_state` enum | "notification_state must be a known state" |
| `graph_depth` ≤ 2 | "graph_depth must be an integer from 0 through 2" |
| `panes` 1–4 | "panes must be an integer from 1 through 4", "panes rejects zero panes" |
| `required_initial_state` shape and cross-checks | `describe "required_initial_state"` |
| `integration.target/base_head/branch_lifecycle` | `describe "integration"` |
| `affects_runtime` boolean, `live_smoke` conditional requirement | `describe "affects_runtime and live_smoke"` |
| `feature_test_inventory_path` relative | "feature_test_inventory_path must be a non-empty relative path" |
| `inputs` / `outputs` non-empty string lists | "inputs must be a non-empty list...", "outputs must be a non-empty list..." |
| `observable_goal` non-empty, single line | "observable_goal must be a non-empty string", "observable_goal must be a single line" |
| `red_tests` / `green_commands` / `repository_gates` / `post_integration_tests` are argv-only, metacharacter-free, non-DB-lifecycle, ≤60000 ms | `describe "command lists"` (parameterized over all four fields) |
| `repository_gates[].when` must be `"handoff"` | `describe "repository_gates handoff cadence"` |
| `stop_conditions` non-empty string list | "stop_conditions must be a non-empty list..." |
| `protected_actions` vocabulary, no duplicates | `describe "protected_actions"` |
| `writers` reject duplicate path ownership | `describe "writers"` — "rejects duplicate writer ownership of the same path" |
| `agent.kind`/`agent.mode` required; Claude auto contract (model, permission_mode, startup_verification) | `describe "agent"` |
| `deletion_decisions` shape | `describe "deletion_decisions"` |
| The shipped example envelope itself validates | "accepts the shipped example envelope" |

## `LaneTaskResult` (`scripts/lane_task_result.exs`)

| Feature | Test |
| --- | --- |
| Unknown field rejected | `test/lane_task_result_test.exs` — "rejects an unsupported field" |
| `task_issue` / `result_path` cross-check the task | "task_issue must equal the task issue", "result_path must equal the task result_path" |
| `status` enum `green`/`red`/`blocked` | "status must be one of green, red, blocked" |
| `commit` required exactly when `status == "green"`, full sha when present | "green status requires a commit", "accepts a red result without a commit", "commit must be a full 40-character lowercase sha when present" |
| `red_evidence` / `green_evidence` non-empty string lists | "red_evidence must be a non-empty list...", "green_evidence must be a non-empty list..." |

## `NotifyParent` (`scripts/notify_parent.exs`)

| Feature | Test |
| --- | --- |
| `validate/2` runs both validators | "validate accepts a matching task and result", "validate rejects an invalid task", "validate rejects an invalid result" |
| `build_event/2` returns exactly eight fixed fields | "build_event produces a fixed, closed set of fields" |
| Event `type` is `lane_task_result` or `lane_task_blocked` | "build_event sends a blocker event when the result is blocked" |
| No lane-authored free text (`red_evidence`/`green_evidence`/`evidence`/`notes`) reaches the event | "build_event never carries child-authored free text such as evidence" |
| Event JSON round-trips deterministically | "build_event output is a fixed, deterministic JSON encoding" |
| Notification target is the exact `parent_agent` | "the parent target for notification is the exact parent_agent from the task" |
| No test contacts Herdr; `send!/2` exists, `send!/3` (a `--wait` variant) does not | "the module never contacts herdr while building an event or validating" |
