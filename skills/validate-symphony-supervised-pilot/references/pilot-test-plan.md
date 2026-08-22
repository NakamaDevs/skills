# Pilot test plan

Use this plan with controls C4 through C11 from the pinned Kaicho
[control source](https://github.com/NakamaDevs/Kaicho/blob/1367d6b2b303d51e95fa6c1681b1dfcc6ca15d0b/docs/governance/harness-and-orchestration-controls.md).
Record commands and results.
Do not copy credential values or full provider payloads into evidence.

## Test identity

- Repository and revision:
- Issue and attempt:
- Operator:
- Deputy:
- Reviewing code owner:
- Supervisor and broker revision:
- Host and UTC window:

## Preflight evidence

| Area | Test | Expected evidence | Result |
| --- | --- | --- | --- |
| Approval | Compare the recorded posture with runtime settings | Exact posture and escalation limit | |
| Filesystem | Resolve the workspace, Git, and common Git paths | Three absolute paths | |
| Filesystem | Attempt direct read, write, and delete on both Git paths | Every operation is denied | |
| Broker | Run each permitted local Git operation | Accepted operations in the broker log | |
| Broker | Target another worktree, repository, and unlisted operation | Every operation is refused | |
| Network | Request one denied destination | Denial with no public listener | |
| Credentials | Inspect the child environment by variable name | No tracker or Git credential names | |
| Audit | Write one synthetic attempt record | Durable, sanitized record | |

Repeat the Git-path denial tests inside an independent clone when the pilot uses
one. Record the clone's three paths separately.

## Recovery test

1. Start one controlled attempt with no external mutation in progress.
2. Restart the supervisor through the approved test control.
3. Confirm that the tracker and workspace rebuild the run state.
4. Confirm that the resumed work has a new attempt number.
5. Confirm that no duplicate branch or pull request exists.
6. Move the test issue to a terminal state.
7. Confirm that the broker performs the recorded terminal cleanup.

Record the attempt history, backoff, stall, turn, and total-runtime limits.

## Emergency-stop tests

Test `stop one run` and `stop all dispatch` separately. For each test, record:

- the actor, reason, and UTC action time;
- the last agent activity time;
- the measured stop time and limit;
- the preserved workspace, branch, and audit record;
- the proof that no new dispatch started.

Do not use a code change, release, or redeploy as the stop action.

## Live pilot execution

1. Read the authorization gate directly from the pinned Kaicho control source.
2. Build the attempt gate from the current canonical controls.
3. Record the source revision, control IDs, evidence links, and gate result.
4. Do not copy the canonical requirements into this reference or the evidence.
5. If the canonical gate blocks the attempt, record the result and stop.
6. If the gate passes, run the authorized attempt and capture event identifiers
   with UTC times.

## Handoff evidence

| Evidence | Value |
| --- | --- |
| Head commit and validation result | |
| Branch and pull request | |
| Attempt record and broker log | |
| Sanitized external-effect log | |
| Restart and stop results | |
| Baseline comparison | |
| Residual risks | |
| Rollback state | |

The effect log must agree with the broker log. A missing or conflicting record
blocks the handoff.
