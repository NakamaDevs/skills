---
name: review-amanuensis-macos
description: Review Amanuensis native macOS and Swift changes. Use when a diff touches app/macos, Swift plugins, method channels, permissions, entitlements, signing, notarization, packaging, or macOS lifecycle.
---

# Review Amanuensis macOS

1. Read `AGENTS.md`, the Linear issue, and final base/head diff.
2. Trace every native method-channel payload/error against its Dart caller and reject malformed input safely.
3. Check actor/main-thread isolation, Sendable boundaries, cancellation, ownership, callbacks, resource cleanup, and permission lifecycle.
4. Review microphone/accessibility permissions, sandbox entitlements, signing, notarization, architectures, upgrades, and privacy-safe logs.
5. Require focused native tests plus macOS build/package evidence on affected architectures.
6. Review rollback and compatibility when permissions, storage, plugin APIs, or packaging change.
7. Report findings by severity; otherwise state no findings and residual risk.
