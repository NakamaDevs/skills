# The notify-parent protocol

[`scripts/notify_parent.exs`](../scripts/notify_parent.exs) tells a lane's
parent agent that the lane finished. It never asks a human to interpret raw
lane output; it validates, builds a fixed event, and submits that event as
one prompt.

## Order of operations

1. Read the task envelope and the result file from the two argv paths.
2. Validate both: `LaneTaskEnvelope.validate/1` on the task, then
   `LaneTaskResult.validate/2` on the result cross-checked against the task
   (`task_issue` and `result_path` must match the task; `commit` is required
   when `status` is `"green"`). Stop on any error; never notify on an invalid
   task or result.
3. Build the event with `NotifyParent.build_event/2`.
4. Encode the event as JSON and call `herdr agent prompt <parent_agent>
   <event-json>` — the exact `parent_agent` named in the task, and never
   with `--wait`.

## The event is fixed and bounded

`build_event/2` returns exactly these nine fields, always:

```json
{
  "type": "lane_task_result",
  "issue": "NAK-452",
  "branch": "feat/NAK-452-enforceable-local-coordinator-agent",
  "role": "lane",
  "parent_task": "kantoku-m0-proven-loop",
  "status": "green",
  "commit": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2",
  "result_path": "results/nak-452-slice-2.json",
  "envelope_digest": "sha256:..."
}
```

`type` is `"lane_task_result"` unless `status` is `"blocked"`, in which case
it is `"lane_task_blocked"` — the parent gets a direct, bounded result event
or a direct, bounded blocker event, distinguished by `type` without changing
the field set. No other field is ever added, and none of these nine is free
text: `issue`, `branch`, `role`, and `parent_task` come from the
already-validated task; `status`, `commit`, and `result_path` come from the
already-validated result; `envelope_digest` is `LaneTaskEnvelope.digest(task)`
(see [envelope-fields.md](envelope-fields.md#binding-an-envelope-to-its-notifications)).
The result's `red_evidence` and `green_evidence` fields are deliberately left
out. Those are where a lane records what it observed, in its own words, and a
coordinator running unattended (see
[claude-auto-contract.md](claude-auto-contract.md)) must not have arbitrary
lane-authored text fed into its next prompt — that text is exactly where a
prompt injection would hide. A coordinator that wants that evidence reads
`result_path` itself, as a file, on its own terms — and, when the scope of a
task was ever unclear, that is what a `stop_conditions` entry and a direct
question to the parent are for, not something folded into this event.

## The parent must verify before acting, not just trust the event

Herdr delivers the prompt text; it does not know what an envelope, a digest,
or a lane task even are, and it applies no authentication or integrity check
of its own. Do not describe Herdr as verifying, authenticating, or binding
anything here — this skill's own code does that, and only when the parent
calls it.

Before acting on an incoming `lane_task_result`/`lane_task_blocked` event, a
coordinator must call `NotifyParent.verify_against_original/2` with the
event and the coordinator's own retained copy of the original envelope it
issued:

```elixir
case NotifyParent.verify_against_original(event, original_envelope) do
  :ok -> # event["envelope_digest"] matches digest(original_envelope); proceed
  {:error, reason} -> # reject: modified envelope, or an event that belongs
                       # to a different original envelope entirely
end
```

Because `envelope_digest` is a sha256 digest of the *entire* envelope, this
one check catches both failure modes named above: an attacker (or a bug)
that tampers with any field of the envelope before an event is built changes
the digest, and an event that genuinely belongs to a different parent's
original envelope will never match this parent's own copy. Skipping this
check and trusting `event["issue"]`/`event["branch"]`/etc. directly would
let a modified or substituted envelope's claims pass through unchecked.

## Why `--wait` is never passed

`herdr agent prompt <target> <text>` submits the event and returns
immediately unless `--wait` is given (see the
[herdr skill](https://github.com/herdrdev/herdr)). `notify_parent.exs` never
passes `--wait`: the lane is finishing, not blocking on the parent's next
turn, and the parent may be mid-turn on other work when the notification
arrives. Waiting here would tie up the lane process for a state change that
is the parent's business, not the lane's.

## What is tested without Herdr

`test/notify_parent_test.exs` exercises `NotifyParent.validate/2`,
`NotifyParent.build_event/2`, `NotifyParent.parent_target/1`, and
`NotifyParent.verify_against_original/2` only. None of those functions calls
`herdr`. Only `NotifyParent.send!/2` shells out (`System.cmd("herdr",
["agent", "prompt", parent_target, event_json])`), and no test calls it —
the test suite instead asserts that `send!/2` exists with exactly that arity
and that no `send!/3` (a hypothetical `--wait`-passing variant) exists at
all. The suite's subprocess tests (real `elixir notify_parent.exs`
invocations, to catch things a pure unit test can't — see the argv-isolation
regression below) only ever pass invalid or wrong-arity input, so they fail
validation and exit before reaching `send!` too.
