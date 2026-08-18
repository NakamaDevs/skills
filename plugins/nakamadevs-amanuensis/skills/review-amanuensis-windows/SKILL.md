---
name: review-amanuensis-windows
description: Review Amanuensis native Windows changes in C++, CMake, Win32, and packaging. Use when a diff touches app/windows, native plugins, method channels, installers, runtime libraries, architecture support, or Windows lifecycle.
---

# Review Amanuensis Windows

1. Read `AGENTS.md`, the Linear issue, and final base/head diff.
2. Trace native method-channel payloads/errors against Dart callers and validate malformed or oversized input.
3. Check lifetime/ownership, RAII, thread affinity, COM initialization, synchronization, cancellation, and UTF conversions.
4. Review permissions, cleanup, DLL/runtime packaging, installer upgrades, x64/ARM64 behavior, long/non-ASCII paths, and privacy-safe logs.
5. Prevent command/path injection and handle locked files, partial installation, and rollback.
6. Require focused native tests plus CMake/build/package evidence for each affected architecture.
7. Report findings by severity; otherwise state no findings and residual risk.
