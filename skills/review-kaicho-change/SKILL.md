---
name: review-kaicho-change
description: Review Kaicho governance, policy scripts, GitHub configuration, runner guidance, and repository-management changes. Use for Kaicho pull-request review, governance rollout verification, or checking whether a policy change remains executable and compatible for adopting repositories.
---

# Review Kaicho change

## Prepare

1. Read `AGENTS.md`, `governance/engineering-v2.md`, and `governance/privacy.md`.
2. Identify the base/head diff and the Linear acceptance criteria.
3. Classify affected areas: contract, documentation, executable checker, GitHub settings/workflow, runner policy, or repository inventory.
4. Read [governance-review.md](references/governance-review.md).

## Review

1. Trace every normative statement to an executable gate, owner, or explicit manual control.
2. Compare scripts, tests, templates, and documentation for drift.
3. Check backward compatibility for repository mirrors and adopters; incompatible semantics require a new major contract file.
4. Test failure paths, missing credentials, protected branches, portability, and safe rollback.
5. Inspect the final diff for security, destructive behavior, unintended repository scope, and missing evidence.

## Report

List findings by severity with file/location, failure mode, impact, and fix. Then state validation reviewed and residual adoption risk. If no findings exist, say so explicitly; do not invent style feedback.
