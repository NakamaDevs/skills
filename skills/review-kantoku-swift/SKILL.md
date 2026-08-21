---
name: review-kantoku-swift
description: Review Kantoku macOS tray changes in Swift and Swift Package Manager. Use when a diff touches nakama_tray, tray state, IPC, menu behavior, macOS lifecycle, entitlements, packaging, or architecture support.
---

# Review Kantoku Swift

1. Read `AGENTS.md`, the Linear issue, and final base/head diff.
2. Trace menu, notification, IPC, persistence, reconnect, relaunch, and backend-state ownership.
3. Check actor/main-thread isolation, Sendable boundaries, cancellation, retain cycles, cleanup, and error recovery.
4. Parse untrusted payloads safely; bound IPC/network calls and prevent secrets in logs/preferences.
5. Review entitlements, signing, launch behavior, accessibility, upgrades, and supported macOS architectures.
6. Require focused Swift tests and build/package evidence on every affected architecture, or record the platform gap.
7. Report actionable findings by severity; otherwise state no findings and residual risk.
