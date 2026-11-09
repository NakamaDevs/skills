---
name: review-kantoku-change
description: Route Kantoku pull-request review across the Elixir/Phoenix/Ash Discord manager, Swift macOS tray, and automation/release stacks. Use for mixed or initially unclassified diffs and invoke only the affected stack review skills.
---

# Review Kantoku change

## Route

1. Read `AGENTS.md`, `.governance/engineering-v2.md`, `.governance/privacy.md`, and the final base/head diff.
2. For `discord_manager/`, invoke `$review-kantoku-elixir` and also follow its nested `AGENTS.md`.
3. For `nakama_tray/`, invoke `$review-kantoku-swift`.
4. For `.github/`, `scripts/`, `mise.toml`, packaging, releases, or deployment, invoke `$review-kantoku-automation`.
5. Invoke multiple skills only when the diff crosses stack boundaries.

## Review

Verify acceptance criteria, correctness, security, concurrency, persistence, compatibility, operational behavior, tests, and rollback. Trace contracts across Discord events, database state, tray state, IPC, packaging, and CI when they cross a boundary. Confirm repository validation commands cover the changed path.

## Report

List actionable findings by severity with file/location, failure mode, impact, and fix. Include reviewed commands/evidence and residual platform risk. Say explicitly when there are no findings.
