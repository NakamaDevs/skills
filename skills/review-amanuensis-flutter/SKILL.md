---
name: review-amanuensis-flutter
description: Review Amanuensis shared Flutter and Dart application changes. Use when a diff touches app/lib, app/test, app/integration_test, shared state, serialization, UI, capture/transcription flows, or cross-platform method-channel callers.
---

# Review Amanuensis Flutter

1. Read `AGENTS.md`, the Linear issue, and final base/head diff.
2. Trace state ownership, widget lifecycle, navigation, loading/error/empty states, serialization, and native-channel contracts.
3. Check mounted/context use after awaits, stream/subscription cleanup, cancellation, isolation of expensive work, and bounded I/O.
4. Review nullability, localization, accessibility, keyboard behavior, privacy boundaries, and sensitive logging.
5. Require focused unit/widget tests and integration coverage for critical cross-platform behavior.
6. Run focused tests before `mise run verify`; record native platforms not exercised.
7. Report findings by severity with failure mode, impact, and fix; otherwise state no findings and residual risk.
