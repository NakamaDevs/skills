---
name: validate-symphony-supervised-pilot
description: Validate the controls and evidence for one supervised Symphony pilot in one repository and one low-risk issue. Use for pilot preflight, controlled fault tests, or human-review handoff; do not use for autonomous merge or production work.
---

# Validate a supervised Symphony pilot

Separate read-only preflight from the live pilot. Default to one repository,
one issue, one agent, and denied network access.

## Inputs

- The repository and exact revision.
- The readiness report and validated `WORKFLOW.md`.
- The low-risk pilot issue and its current attempt number.
- The operator, deputy, and independent reviewing code owner.
- The supervisor, broker, audit sink, stop controls, limits, and rollback.

Read controls C4 through C11 from the pinned Kaicho
[control source](https://github.com/NakamaDevs/Kaicho/blob/1367d6b2b303d51e95fa6c1681b1dfcc6ca15d0b/docs/governance/harness-and-orchestration-controls.md).
Read
[the pilot test plan](references/pilot-test-plan.md) only when runtime tests are
in scope.

## Preflight

1. Confirm that repository readiness passes at the exact pilot revision.
2. Run the workflow safety validator and repository validation ladder.
3. Verify the three resolved workspace and Git paths.
4. Run the broker's positive and negative boundary tests.
5. Verify the denied network posture and sanitized child environment.
6. Verify the audit sink, attempt limits, restart recovery, and both stop
   controls.
7. Confirm that the baseline and rollback are recorded.

Do not read credential values. Test only their absence, holder, scope, and
delivery boundary.

## Authorization boundary

Finish preflight before you request a live run. Immediately before dispatch or
another external mutation, ask the operator to authorize the exact repository,
issue, attempt, effect set, and time window.

One authorization covers one attempt only. It never permits merge, force push,
public ingress, release, deployment, production writes, credential changes, or
credential disclosure.

## Permitted tools

Use local checks, read-only tracker and Git hosting APIs, supervisor status,
the repository-scoped Git broker test interface, and sanitized audit records.
Use mutating tools only after the immediate authorization step.

## Stop conditions

Use the emergency stop for a sandbox, network, broker, audit, or external-effect
control failure. Stop for a suspected credential leak. Stop if either stop
control misses its limit or an independent reviewer is unavailable.

Keep the workspace, branch, broker log, and audit record after an emergency
stop. Revoke a suspected credential before any history cleanup.

## Output and quality gates

Return `authorized`, `blocked`, or `stopped`. Include exact test evidence,
sanitized effects, restart results, stop times, residual risks, and rollback.

A successful run ends at human review. Never merge the pull request or mark the
pilot successful from a retry alone.
