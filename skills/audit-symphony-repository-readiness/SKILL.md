---
name: audit-symphony-repository-readiness
description: Audit one repository for the local knowledge, architecture checks, validation commands, and governance declaration required before a supervised Symphony pilot. Use for readiness reports and gap analysis, not for changing the repository or starting a pilot.
---

# Audit Symphony repository readiness

Audit one repository at a time. Use local evidence before remote evidence.

## Inputs

- The repository root and intended default branch.
- The exact governance source or an approved local mirror.
- The repository revision that the evidence describes.

Use Kaicho commit `1367d6b2b303d51e95fa6c1681b1dfcc6ca15d0b`
when the user does not select a later approved source. Read the pinned
[engineering contract](https://github.com/NakamaDevs/Kaicho/blob/1367d6b2b303d51e95fa6c1681b1dfcc6ca15d0b/governance/engineering-v1.md)
and [harness controls](https://github.com/NakamaDevs/Kaicho/blob/1367d6b2b303d51e95fa6c1681b1dfcc6ca15d0b/docs/governance/harness-and-orchestration-controls.md).

## Workflow

1. Read every applicable `AGENTS.md` and repository-owned rule.
2. Inspect `.nakama/repository.toml`, the knowledge index, architecture rules,
   validation tasks, hooks, CI, ownership, and secret checks.
3. Run only local, read-only discovery commands at first.
4. Run documented local checks when they do not need a credential or a paid
   service.
5. Mark each claim as `pass`, `fail`, `unverified`, or `not-applicable`.
6. Use [the readiness report](references/readiness-report.md) for the result.

Do not infer a pass from a file name. Record the command, revision, host, and
result for each executable check.

## Permitted tools

Use local file reads, search, read-only Git commands, and repository validation
commands. Use read-only remote APIs only when local evidence cannot prove a
claim and the user has supplied access.

Do not edit files, change tracker data, push, open a pull request, start
Symphony, or inspect credential values. Report credential names and scopes only.

## Stop conditions

Stop and report `unverified` when the canonical source is unavailable. Stop
when the repository root or target revision is ambiguous. Do not continue past
a local check failure to obtain a better result from a later check.

## Quality gates and output

The report must map evidence to the repository adoption gate and controls C1
through C3. It must distinguish missing evidence from failed evidence.

Return the readiness decision, blocking gaps, exact evidence, residual risks,
and the smallest safe next action. Never set `harness.agent_ready` as part of
this audit.
