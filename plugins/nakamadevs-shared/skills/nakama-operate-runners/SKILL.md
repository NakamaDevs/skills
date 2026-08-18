---
name: nakama-operate-runners
description: Inspect, provision, recover, or change NakamaDevs self-hosted GitHub Actions runners across macOS, Linux, and Windows. Use for runner health, labels, services, host bootstrap, workflow routing, canary rollout, or Runner Fleet changes.
---

# Nakama Operate Runners

1. Read `.nakama/repository.toml`, applicable `AGENTS.md`, and [runner invariants](references/invariants.md). Treat Runner Fleet as the source of truth for hosts and labels.
2. Start read-only: inspect workflow demand, organization runner inventory, service state, architecture, labels, queued jobs, disk, and logs without exposing credentials.
3. For repository-only failures, reproduce repository validation before changing a host. Do not mask application failures by mutating fleet state.
4. For a requested recovery, use repository-owned idempotent status/up commands. Canary one host, verify GitHub visibility and a representative job, then expand.
5. For provisioning or configuration changes, pin downloads with version and checksum, use least-privilege service identities, preserve rollback, and validate every affected host family.
6. Never rotate credentials, stop runners, delete services, or broaden labels without explicit scope. Keep registration tokens out of prompts, shell history, logs, fixtures, and PRs.
7. Record before/after health, commands, host coverage, observation window, and rollback. Route code changes through `$nakama-deliver-change` and `$nakama-review-change`.

Use `$nakama-discord-operations` for `/kantoku jobs`, `/kantoku hosts`, or the idempotent runner recovery command.
