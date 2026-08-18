---
name: code-review-production
description: Review changed runtime and delivery behavior for resilience, bounded resources, cancellation, observability, configuration safety, reproducible builds, compatibility, rollback, and operational support. Use when code can affect deployed or distributed artifacts, long-running processes, or user operations.
---

# Review Production Readiness

Review against the product's real operating model, not an assumed cloud-service checklist.

## Runtime

- Bound memory, input size, output size, goroutines, queues, retries, and time.
- Propagate cancellation and deadlines across blocking work.
- Close files, bodies, processes, listeners, timers, and goroutines on every path.
- Make retries safe through idempotency or explicit duplicate handling.
- Preserve useful errors while avoiding secrets and private data in logs.
- Define behavior for partial failure, startup failure, shutdown, restart, and interrupted work.

## Delivery and compatibility

- Keep builds reproducible from pinned source and dependencies.
- Test the artifact that will actually ship, not only a development path.
- Preserve configuration and persisted-data compatibility or provide an explicit migration.
- Identify rollback limits for irreversible state or contract changes.
- Avoid undeclared network, CDN, working-directory, platform, or toolchain dependencies.
- Require performance claims to have measurements on a representative path.

For Mensetsukan, released binaries must embed runtime assets and need no CDN, Python, Node.js, or working directory. The server must remain loopback-only, the MCP server read-only and stateless, and browser session restoration/reset behavior explicit. Apply service-oriented observability only where a real operational consumer exists.

## Finding gate

Report a concrete production scenario: leak, hang, unbounded work, unrecoverable partial state, incompatible rollout, missing packaged asset, platform failure, or unobservable failure that prevents support. Avoid generic requests for dashboards, retries, or abstraction without an applicable runtime need.

Return candidates using the orchestrator contract, or `No findings.`
