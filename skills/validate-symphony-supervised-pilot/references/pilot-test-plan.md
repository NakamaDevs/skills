# Pilot test plan

Use this plan with controls C4 through C11 from Kaicho commit
`1367d6b2b303d51e95fa6c1681b1dfcc6ca15d0b`. Record commands and results.
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

## Live pilot gate

Before dispatch, confirm these facts:

- one low-risk issue has the required pilot label;
- the issue excludes release, deployment, security, credential, and billing
  work;
- the operator authorizes this exact attempt and closed effect set;
- no production credential enters the agent environment;
- the independent reviewer is available.

Stop the run at human review. Do not merge.

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
