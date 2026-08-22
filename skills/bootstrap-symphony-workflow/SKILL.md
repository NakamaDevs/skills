---
name: bootstrap-symphony-workflow
description: Create or repair a repository-owned WORKFLOW.md for one supervised, low-risk Symphony pilot. Use after repository readiness passes; do not use to start Symphony, enable dispatch, or configure production work.
---

# Bootstrap a Symphony workflow

Create one repository-specific `WORKFLOW.md`. Keep the file inactive until all
pilot gates pass.

## Inputs

- A passing repository-readiness report for the target revision.
- The Linear project slug, state names, and one pilot label.
- The workspace-root environment name.
- The fixed operations, tool interface, and environment name for the
  repository-scoped Git broker.
- The local validation commands and the human-review handoff state.

Use Kaicho commit `1367d6b2b303d51e95fa6c1681b1dfcc6ca15d0b` as the
canonical [control source](https://github.com/NakamaDevs/Kaicho/blob/1367d6b2b303d51e95fa6c1681b1dfcc6ca15d0b/docs/governance/harness-and-orchestration-controls.md).
Use the pinned Symphony specification in
[the safe workflow guide](references/safe-workflow.md) only for file syntax and
runtime behavior.

## Workflow

1. Read every applicable `AGENTS.md`, the readiness report, and the existing
   `WORKFLOW.md` when present.
2. Confirm that `.nakama/repository.toml` declares `harness.agent_ready = true`.
3. Read [the safe workflow guide](references/safe-workflow.md).
4. Preserve repository commands, state names, and user constraints.
5. Write the smallest complete workflow that uses one agent and denied network
   access.
6. Route all Git effects through the declared repository-scoped broker.
7. Keep credential values out of the file. Use host-side environment
   references.
8. Run `scripts/validate_workflow_safety.py` from this skill against the file.
9. Run the repository checks and review the final diff.

The prompt must stop at human review. It must prohibit merge, force push,
release, deployment, production writes, public ingress, and credential access.

## Permitted tools

Use local file reads, local edits requested by the user, read-only Git commands,
the included validator, and repository checks. Do not start or reload Symphony.

Ask for authorization immediately before any external mutation. Name the
repository, issue, attempt, and exact effect. One authorization does not cover
another attempt.

## Stop conditions

Stop when readiness does not pass. Stop when the broker, workspace boundary,
handoff state, or validation commands are unknown. Stop if the existing file
has overlapping user changes. Never replace an unknown with an unsafe default.

## Output and quality gates

Return the changed file, validator result, repository checks, unresolved pilot
gates, and rollback. A valid `WORKFLOW.md` does not authorize a pilot.
