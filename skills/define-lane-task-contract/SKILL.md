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
- The exact `integration.target` branch and `integration.base_head` commit
  this task integrates against.
- The observable goal, inputs, outputs, and `feature_test_inventory_path`
  the coordinator expects.
- The RED tests, GREEN commands, repository gates, and (when the task
  affects a running instance of the software) the `live_smoke` check.
- Whether this task may delegate to a further sub-agent (`delegation_allowed`);
  a task at `graph_depth == 2` is a leaf and never may.

Read [envelope-fields.md](references/envelope-fields.md) for the full field
list, [command-safety.md](references/command-safety.md) for the argv and
timeout rules, and
[claude-auto-contract.md](references/claude-auto-contract.md) when
`agent.kind` is `"claude"` and `agent.mode` is `"auto"`. Every automated
Claude or Codex lane also names `agent.model`, `agent.effort`, and
`agent.routing_reason`; [model-routing.md](references/model-routing.md) is
the workspace routing policy (supported models, per-model effort
vocabularies, balanced Codex and Claude routes, the default agent graph, and
the five measurements to record after each run). When
`agent.kind` is `"codex"` and `agent.mode` is `"auto"`, `agent.command` is
required and must include `-c check_for_update_on_startup=false` — see
[command-safety.md](references/command-safety.md#every-codex-startup-command-disables-the-interactive-update-prompt);
the same flag is required on any other command that starts `codex`
anywhere in the envelope, so an unattended agent never faces an
interactive update prompt it cannot answer. Read
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
   `valid`. This CLI run already checked two things live, not just the
   schema: it shells out to `git` in the envelope's declared `worktree`,
   after schema validation passes, to confirm `integration.base_head`
   exists and equals the actual merge base of `branch` and
   `integration.target` — an unknown or stale `base_head` fails this same
   command with a clear message — and it then resolves every `writers[].path`
   through any real symlink on disk to confirm none of them actually
   escapes the worktree, which a purely lexical check (string algebra on
   `..`/`.` segments) cannot see. Calling `LaneTaskEnvelope.validate/1`
   directly from other code, without going through this CLI, does not get
   either check for free; call `resolve_integration_head/2` and
   `resolve_writer_paths/1` explicitly in that case. For a v1 migration
   branch, the coordinator must also supply the trusted base revision through
   `LANE_TRUSTED_POLICY_REVISION`. Do not copy this revision from the envelope.
5. Run `red_tests` and confirm they fail, then implement, then run
   `green_commands` and confirm they pass. Run `repository_gates` once, at
   handoff — not after every intermediate commit. If `affects_runtime` is
   `true`, also run `live_smoke` against the actually running software, not
   only its unit-level double.
6. After the branch integrates into `integration.target`, run
   `post_integration_tests` against the resulting trunk before treating the
   task as finished. The next lane task for this issue starts from that
   updated trunk head, not from a stale `base_head`.
7. When the lane finishes and writes its result file, validate the result
   against the task and notify the parent:

   ```
   elixir skills/define-lane-task-contract/scripts/notify_parent.exs <path-to-envelope.json> <path-to-result.json>
   ```

   [notify-parent-protocol.md](references/notify-parent-protocol.md)
   describes what `notify_parent.exs` sends and why.
8. Acting as the parent (coordinator) receiving that event: call
   `NotifyParent.verify_against_original/2` with the event and the
   coordinator's own retained original envelope before doing anything with
   it. Herdr delivered the prompt text; it did not verify the event belongs
   to this task, was not modified, or came from the parent's own lane —
   this skill's code does that, and only when this step actually runs.

## Permitted tools

Use local file reads and edits to the envelope, result, and this skill's own
files. Use `elixir` to run the validators and the ExUnit suite in `test/`.
Use `mise run verify:quick` to run the repository's own gates.

Do not run `notify_parent.exs` against a live `parent_agent` unless the user
named that exact target and asked for the notification, or that target is a
real herdr agent the user has otherwise confirmed is ready to receive it;
`notify_parent.exs` submits a real prompt through `herdr agent prompt`, which
is a visible action in another agent's pane.

Do not post detailed RED/GREEN test logs, per-commit status, or other
implementation-level detail to Linear. Linear gets a human project update
only after a material milestone (a slice lands, a gate that was failing now
passes, the loop notified its parent) — not on every commit and not as a
substitute for `red_evidence`/`green_evidence`, which live in the result
file, not the tracker.

## Stop conditions

Stop and report the exact validator errors when the envelope or result fails
validation. Never hand-patch around a validation error by removing a field
from `references/envelope-fields.md`'s list or from the validator's
allow-lists; treat every rejection as the envelope being wrong, not the
validator.

Stop before calling `notify_parent.exs` for real when the `parent_agent`
target is unknown, unconfirmed, or not currently running.

When the requested scope is unknown or ambiguous, that is itself a stop
condition: ask the parent agent (or the user, when there is no parent turn to
ask) before editing. Guessing at scope and then trying to relabel the result
as a "blocker" after the fact does not substitute for asking first.

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

Update [`references/feature-test-inventory.md`](references/feature-test-inventory.md)
in the same change that adds, changes, or removes an enforceable rule. Record
any deletion of existing behavior or an existing test in
`deletion_decisions`, with its replacement decision, rather than dropping it
silently.

Return the exact validator output (or ExUnit summary), not just "it works."
A valid envelope does not authorize a lane to run; it only proves the
contract is well-formed.
