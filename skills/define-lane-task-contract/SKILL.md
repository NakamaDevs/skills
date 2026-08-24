---
name: define-lane-task-contract
description: Create and validate a durable, test-first lane task envelope that a coordinator hands to one lane agent, and notify the exact parent agent when the lane finishes. Use when authoring or checking a lane task contract, its RED tests, GREEN commands, repository gates, or Claude auto contract. Do not use this skill to build the coordinator agent itself or to run a lane task.
---

# Define a lane task contract

Author one lane task envelope: a single JSON file a coordinator hands to one
lane agent. The envelope is durable (it is the record of what the lane was
asked to do and under what constraints) and test-first (it names the RED
tests that must fail before implementation and the GREEN commands that must
pass after).

## Inputs

- The issue, owner, branch, and worktree for the lane task.
- The parent task id and the exact `parent_agent` herdr target that must
  receive the finished notification.
- The observable goal, inputs, and outputs the coordinator expects.
- The RED tests, GREEN commands, and repository gates the lane must run.

Read [envelope-fields.md](references/envelope-fields.md) for the full field
list, [command-safety.md](references/command-safety.md) for the argv and
timeout rules, and
[claude-auto-contract.md](references/claude-auto-contract.md) when
`agent.kind` is `"claude"` and `agent.mode` is `"auto"`. Read
[the example envelope](examples/task-envelope.json) before writing a new one;
copy its shape rather than inventing a new one.

## Workflow

1. Read the existing envelope, if one exists, and every applicable
   `AGENTS.md`.
2. Draft or edit the envelope JSON. Fill in every field in
   [envelope-fields.md](references/envelope-fields.md); do not add a field
   that is not listed there.
3. Validate it:

   ```
   elixir skills/define-lane-task-contract/scripts/lane_task_envelope.exs <path-to-envelope.json>
   ```

4. Fix every reported error and re-run the validator until it prints
   `valid`.
5. When the lane finishes and writes its result file, validate the result
   against the task and notify the parent:

   ```
   elixir skills/define-lane-task-contract/scripts/notify_parent.exs <path-to-envelope.json> <path-to-result.json>
   ```

   [notify-parent-protocol.md](references/notify-parent-protocol.md)
   describes what `notify_parent.exs` sends and why.

## Permitted tools

Use local file reads and edits to the envelope, result, and this skill's own
files. Use `elixir` to run the validators and the ExUnit suite in `test/`.
Use `mise run verify:quick` to run the repository's own gates.

Do not run `notify_parent.exs` against a live `parent_agent` unless that
target is a real herdr agent the user has confirmed is ready to receive it;
`notify_parent.exs` submits a real prompt through `herdr agent prompt`, which
is a visible action in another agent's pane.

## Stop conditions

Stop and report the exact validator errors when the envelope or result fails
validation. Never hand-patch around a validation error by removing a field
from `references/envelope-fields.md`'s list or from the validator's
allow-lists; treat every rejection as the envelope being wrong, not the
validator.

Stop before calling `notify_parent.exs` for real when the `parent_agent`
target is unknown, unconfirmed, or not currently running.

## Output and quality gates

Every change to the validators or `notify_parent.exs` needs a red test
first: write or edit the ExUnit assertion, confirm it fails against the
current implementation, then implement until it passes. Run the focused
suite before any change is considered done:

```
elixir skills/define-lane-task-contract/test/lane_task_envelope_test.exs
elixir skills/define-lane-task-contract/test/lane_task_result_test.exs
elixir skills/define-lane-task-contract/test/notify_parent_test.exs
```

Return the exact validator output (or ExUnit summary), not just "it works."
A valid envelope does not authorize a lane to run; it only proves the
contract is well-formed.
