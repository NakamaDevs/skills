---
name: review-runner-fleet-windows
description: Review Runner Fleet Windows and PowerShell changes. Use when a diff touches Windows bootstrap, services, scheduled tasks, runner installation, ACLs, host architecture, downloads, updates, or PowerShell operations.
---

# Review Runner Fleet Windows

1. Read `AGENTS.md`, the Linear issue, final diff, fleet manifest, and operations docs.
2. Resolve exact hosts, accounts, services/tasks, labels, architectures, and consumer workflows.
3. Check explicit error behavior, safe argument arrays/literal paths, idempotency, elevation, ACLs, service recovery, and reboot persistence.
4. Review x64/ARM64, PowerShell editions, long/non-ASCII paths, locked files, antivirus, partial package failure, and redacted diagnostics.
5. Verify downloads/signatures; require atomic updates, canary health gates, configuration/service rollback, and observation.
6. Require parser/analyzer checks, fixtures, dry-run/status evidence, and affected-host validation.
7. Report findings by severity with fleet blast radius and fix; otherwise state no findings and residual risk.
