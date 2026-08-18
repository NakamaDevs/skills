---
name: review-runner-fleet-unix
description: Review Runner Fleet macOS, Linux, and POSIX shell changes. Use when a diff touches Unix bootstrap, launchd/systemd services, runner installation, updates, labels, host architecture, downloads, or shell operations.
---

# Review Runner Fleet Unix

1. Read `AGENTS.md`, the Linear issue, final diff, fleet manifest, and operations docs.
2. Resolve exact hosts, users, services, labels, architectures, and consumer workflows before assessing mutation.
3. Check quoting, unsafe eval/globs, strict-mode behavior, idempotency, interruption, partial failure, signals, cleanup, and reboot persistence.
4. Review root/user boundaries, ownership, permissions, launchd/systemd differences, Intel/ARM paths, and non-interactive execution.
5. Pin and verify downloads; require atomic replacement, canary health gates, rollback, and observable recovery.
6. Require shell syntax/lint, fixtures, dry-run/status evidence, and affected-host validation.
7. Report findings by severity with fleet blast radius and fix; otherwise state no findings and residual risk.
