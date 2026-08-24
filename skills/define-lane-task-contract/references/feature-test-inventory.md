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
| `delegation_allowed` boolean; must be `false` at `graph_depth == 2` (a leaf) | `describe "delegation_allowed and leaf commands"` |
| An attempted `herdr agent start`/`agent prompt` delegation command is rejected in any command field when `delegation_allowed` is `false`, including wrapped in `env`/`mise exec --` or path-qualified | "rejects an attempted herdr agent start delegation...", "rejects an attempted herdr agent prompt delegation...", "rejects a herdr agent start delegation wrapped in env", "rejects a herdr agent start delegation wrapped in mise exec --", "rejects a path-qualified herdr agent start delegation", "rejects a path-qualified herdr agent start delegation wrapped in mise exec --" |
| `required_initial_state` shape and cross-checks | `describe "required_initial_state"` |
| `integration.target/base_head/branch_lifecycle` (schema shape only — see `resolve_integration_head/1` below for the live check) | `describe "integration"` |
| `affects_runtime` boolean, `live_smoke` conditional requirement | `describe "affects_runtime and live_smoke"` |
| `live_smoke.command` does not exist and is rejected in every form — a plain previously allow-listed name, a relative path, an untrusted absolute path, and each wrapped in `env` (including a `PATH` override)/`mise exec --`/`sh -c` — because a basename allow-list still trusts an attacker-controllable executable string; no absolute path for curl/wget/nc/ncat/grpc_health_probe is portable across this project's Linux, macOS, and Windows runners | parameterized: "live_smoke rejects a plain, previously allow-listed probe name/a relative path/an untrusted absolute path/a PATH override wrapped in env/a relative path wrapped in mise exec --/an untrusted absolute path wrapped in sh -c — command is not a permitted field" |
| `live_smoke.endpoint` (url, expect_status) is the only permitted `live_smoke` shape and is required | "declared endpoint health contract is the only permitted live_smoke shape", "live_smoke.endpoint is required", "live_smoke.endpoint requires a non-empty url", "live_smoke.endpoint requires expect_status to be a valid HTTP status integer" |
| `feature_test_inventory_path` relative | "feature_test_inventory_path must be a non-empty relative path" |
| `inputs` / `outputs` non-empty string lists | "inputs must be a non-empty list...", "outputs must be a non-empty list..." |
| `observable_goal` non-empty, single line | "observable_goal must be a non-empty string", "observable_goal must be a single line" |
| `red_tests` / `green_commands` / `repository_gates` / `post_integration_tests` are argv-only, metacharacter-free, non-DB-lifecycle, ≤60000 ms | `describe "command lists"` (parameterized over all four fields) |
| A manual database lifecycle command is rejected even wrapped in `env`, `mise exec --`, `sh -c`, or `bash -c` | "...rejects a manual database lifecycle command wrapped in env/mise exec --/sh -c/bash -c" (parameterized) |
| `repository_gates[].when` must be `"handoff"` | `describe "repository_gates handoff cadence"` |
| `stop_conditions` non-empty string list | "stop_conditions must be a non-empty list..." |
| `protected_actions` vocabulary, no duplicates | `describe "protected_actions"` |
| `writers` paths are canonicalized relative to `worktree` (dot segments, resolvable `..`), reject an escape, and reject duplicate or ancestor/descendant-overlapping ownership | `describe "writers"` |
| `agent.kind`/`agent.mode` required; Claude auto contract (model, permission_mode, startup_verification) | `describe "agent"` |
| An automated Codex role (`agent.kind == "codex"`, `agent.mode == "auto"`) requires `agent.command`, which must include `-c check_for_update_on_startup=false` | "an automated codex role template requires a command", "an automated codex role template requires the update-prompt guard", "an automated codex role template with the update-prompt guard is accepted" |
| Any command that starts `codex` (in `red_tests`/`green_commands`/`repository_gates`/`post_integration_tests`) must include `-c check_for_update_on_startup=false`, to prevent an unattended agent from facing an interactive Codex update prompt on startup | "a command that starts codex without the update-prompt guard is rejected", "a command that starts codex with the update-prompt guard is accepted" |
| `deletion_decisions` shape | `describe "deletion_decisions"` |
| The shipped example envelope itself validates | "accepts the shipped example envelope" |
| The CLI requires exactly one operand; zero or surplus exits 2 | `describe "the CLI entry point (subprocess)"` |
| `resolve_integration_head/1` (live git check, NOT part of `validate/1`) resolves `integration.target`/`integration.base_head` in the declared worktree and matches the real merge base | `describe "resolve_integration_head/1 (live git verification, not part of validate/1)"` |
| The normal documented CLI (`elixir lane_task_envelope.exs <envelope.json>`) runs `resolve_integration_head/1` too, and rejects an unknown or stale `base_head` in a temporary repository | `describe "the CLI entry point also runs the live integration-head check (temporary repository)"` |
| `resolve_writer_paths/1` (live, symlink-aware filesystem check, NOT part of `validate/1`) resolves every existing path component's real symlink target and rejects a writer path that lexically stays inside the worktree but escapes through one; accepts normal and `..`-resolving paths with no symlink | `describe "resolve_writer_paths/1 (live, symlink-aware filesystem check; not part of validate/1)"` |
| The normal documented CLI runs `resolve_writer_paths/1` too, and rejects a symlink-based writer-path escape in a temporary worktree | `describe "the CLI entry point also runs the writer-path symlink check (temporary repository)"` |
| `digest/1` is a stable, content-sensitive sha256 digest of the envelope | `describe "digest"` |

## `LaneTaskResult` (`scripts/lane_task_result.exs`)

| Feature | Test |
| --- | --- |
| Unknown field rejected | `test/lane_task_result_test.exs` — "rejects an unsupported field" |
| `task_issue` / `result_path` cross-check the task | "task_issue must equal the task issue", "result_path must equal the task result_path" |
| `status` enum `green`/`red`/`blocked` | "status must be one of green, red, blocked" |
| `commit` required exactly when `status == "green"`, full sha when present | "green status requires a commit", "accepts a red result without a commit", "commit must be a full 40-character lowercase sha when present" |
| `commit` may be entirely omitted (not just null) for a `red`/`blocked` result; required for `green` | "commit may be entirely omitted for a red result", "commit may be entirely omitted for a blocked result", "commit omission is rejected for a green result" |
| `red_evidence` / `green_evidence` non-empty string lists | "red_evidence must be a non-empty list...", "green_evidence must be a non-empty list..." |
| The CLI requires exactly two operands, in order; zero or surplus exits 2 | `describe "the CLI entry point (subprocess)"` |

## `NotifyParent` (`scripts/notify_parent.exs`)

| Feature | Test |
| --- | --- |
| `validate/2` runs both validators | "validate accepts a matching task and result", "validate rejects an invalid task", "validate rejects an invalid result" |
| `build_event/2` returns exactly nine fixed fields, including `envelope_digest` | "build_event produces a fixed, closed set of fields" |
| Event `type` is `lane_task_result` or `lane_task_blocked` | "build_event sends a blocker event when the result is blocked" |
| No lane-authored free text (`red_evidence`/`green_evidence`/`evidence`/`notes`) reaches the event | "build_event never carries child-authored free text such as evidence" |
| Event JSON round-trips deterministically | "build_event output is a fixed, deterministic JSON encoding" |
| Notification target is the exact `parent_agent` | "the parent target for notification is the exact parent_agent from the task" |
| `verify_against_original/2` accepts a matching digest, rejects a modified envelope, and rejects an event that belongs to an alternate parent's original envelope | `describe "verify_against_original/2 (parent-side, before any action)"` |
| No test contacts Herdr; `send!/2` exists, `send!/3` (a `--wait` variant) does not | "the module never contacts herdr while building an event or validating" |
| Requiring `lane_task_envelope.exs`/`lane_task_result.exs` from inside `notify_parent.exs` must not trigger their own CLI guards with the outer argv | "validates the result against the result schema, not against the task's own fields" |
| The CLI requires exactly two operands; zero or surplus exits 2 | "exits 2 with zero operands", "exits 2 with surplus operands" |

## Repository configuration (`tests/test_lane_task_contract_configuration.py`)

| Feature | Test |
| --- | --- |
| `elixir` stays pinned in `mise.toml` | "test_elixir_is_pinned_for_the_dependency_free_validators" |
| `lane-task-contract:test` keeps running all three focused suites | "test_lane_task_contract_test_task_runs_all_three_focused_suites" |
| `verify:quick` keeps calling `lane-task-contract:test` | "test_verify_quick_runs_lane_task_contract_tests" |
