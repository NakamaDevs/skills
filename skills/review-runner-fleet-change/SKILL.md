---
name: review-runner-fleet-change
description: Review Runner Fleet infrastructure changes across macOS, Linux, Windows, shell, PowerShell, GitHub Actions, labels, secrets, services, and fleet rollout. Use for pull-request review, host automation review, or pre-deployment inspection.
---

# Review Runner Fleet change

## Prepare

1. Read `AGENTS.md`, `.governance/engineering-v1.md`, the Linear issue, and final base/head diff.
2. Identify affected host families, architectures, labels, service accounts, secrets, workflows, and consumer repositories.
3. Read [fleet-review.md](references/fleet-review.md). Invoke `$review-runner-fleet-unix` for shell/macOS/Linux and `$review-runner-fleet-windows` for PowerShell/Windows. Invoke both for shared manifests, labels, or routing contracts.

## Review

Check least privilege, idempotency, safe quoting, secret handling, concurrency, service recovery, architecture, labels/routing, observability, canary order, and rollback. Follow changes through config, bootstrap, service install, status/validation, CI selection, and consumer assumptions. Require evidence per affected host family or record the gap.

## Report

List findings by severity with file/location, failure mode, fleet blast radius, and fix. Then state validation, rollout/rollback evidence, and untested hosts. Say explicitly when there are no findings.
