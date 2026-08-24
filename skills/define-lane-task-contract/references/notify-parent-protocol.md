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

`build_event/2` returns exactly these eight fields, always:

```json
{
  "type": "lane_task_result",
  "issue": "NAK-452",
  "branch": "feat/cx/nak-452-enforceable-local-coordinator-agent",
  "role": "lane",
  "parent_task": "coordinator-nak-452-slice-1",
  "status": "green",
  "commit": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2",
  "result_path": "results/nak-452-slice-1.json"
}
```

No other field is ever added, and none of these eight is free text: `issue`,
`branch`, `role`, and `parent_task` come from the already-validated task;
`status`, `commit`, and `result_path` come from the already-validated
result. The result's `evidence` field is deliberately left out. `evidence` is
where a lane records what it observed, in its own words, and a coordinator
running unattended (see [claude-auto-contract.md](claude-auto-contract.md))
must not have arbitrary lane-authored text fed into its next prompt — that
text is exactly where a prompt injection would hide. A coordinator that wants
the evidence reads `result_path` itself, as a file, on its own terms.

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
`NotifyParent.build_event/2`, and `NotifyParent.parent_target/1` only. None
of those functions calls `herdr`. Only `NotifyParent.send!/2` shells out
(`System.cmd("herdr", ["agent", "prompt", parent_target, event_json])`), and
no test calls it — the test suite instead asserts that `send!/2` exists with
exactly that arity and that no `send!/3` (a hypothetical `--wait`-passing
variant) exists at all.
