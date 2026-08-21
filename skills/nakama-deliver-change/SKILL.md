---
name: nakama-deliver-change
description: Deliver a NakamaDevs repository change from a Linear issue through research, planning, implementation, validation, review, and a protected-main pull request. Use for feature, fix, maintenance, release, or incident follow-up work in a repository with .nakama/repository.toml.
---

# Nakama Deliver Change

1. Read `.nakama/repository.toml`, the root and applicable nested `AGENTS.md`, and the local governance mirror. If context is missing or incompatible with this catalog fallback, use `$nakama-adopt-governance` before changing code.
2. Resolve the Linear issue and confirm its team and project match repository context. For urgent incidents, proceed only within incident scope and require a backfill issue.
3. Research affected code, tests, workflows, release paths, and operational consumers before editing. Record material unknowns and risks.
4. Plan the smallest cohesive change, acceptance evidence, rollout, rollback, and platform coverage. Keep coordination state in Linear or the PR.
5. Implement on the context-defined branch pattern from protected `main`.
   When repository policy requires Herdr, keep the primary checkout clean and
   create or reopen the issue's linked child worktree before editing. Preserve
   unexpected dirty work through a named recoverable backup; do not reset it to
   make branch setup convenient. Treat sandbox failures involving Herdr's
   socket, keyring-backed credentials, network access, or Git common-directory
   writes as execution-boundary probes and retry only the narrow command with
   approved access before declaring the service or credential broken.
6. Run focused checks, then `quality.quick`, then `quality.full` from repository context. Treat hooks as feedback and CI as authoritative. Never claim an unrun check.
7. Invoke `$nakama-review-change` on the final base/head diff. Resolve findings and conversations before delivery.
8. When publication is authorized, use Conventional Commits, push the existing branch, and create or update one PR. Request CODEOWNERS, link Linear, and report validation, risks, release impact, and rollback.

Do not add `ready_for_review` when existing PR events already test the same commit. Do not bypass protected `main`, code-owner approval, secret scanning, or supply-chain gates.
