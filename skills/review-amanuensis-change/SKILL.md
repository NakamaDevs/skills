---
name: review-amanuensis-change
description: Route Amanuensis pull-request review across Flutter/Dart, Swift/macOS, C++/Windows, and CI/release stacks. Use for mixed or initially unclassified diffs and invoke only the affected platform review skills.
---

# Review Amanuensis change

## Route

1. Read `AGENTS.md`, `.governance/engineering-v2.md`, `.governance/privacy.md`, and the final base/head diff.
2. For `app/lib`, `app/test`, or `app/integration_test`, invoke `$review-amanuensis-flutter`.
3. For `app/macos` or Swift changes, invoke `$review-amanuensis-macos`.
4. For `app/windows`, C++, or CMake changes, invoke `$review-amanuensis-windows`.
5. For `.github`, toolchains, packaging, versioning, or release changes, invoke `$review-amanuensis-release`.
6. Invoke multiple skills when shared/native or build/platform contracts cross boundaries.

## Review

Verify behavior, privacy/security, lifecycle, concurrency, error recovery, platform compatibility, accessibility, tests, packaging, upgrade, and rollback. Trace method-channel and data contracts end to end. Treat unavailable platform validation as residual risk, not assumed success.

## Report

List findings by severity with file/location, failure mode, impact, and fix. Record reviewed evidence and untested platforms. Say explicitly when there are no findings.
