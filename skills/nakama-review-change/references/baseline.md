# NakamaDevs review baseline

Load only sections relevant to the diff.

- Correctness: contracts, edge cases, error paths, state transitions, concurrency, and compatibility.
- Security: trust boundaries, least privilege, input validation, logging, data exposure, and safe defaults.
- Supply chain: exact versions, committed locks, seven-day routine age floor, checksums, signatures, full-SHA Actions, and reviewed scripts.
- Secrets: no credentials in source or output; redacted staged/history scans; narrow exceptions; revoke before cleanup.
- Quality: focused tests before aggregate checks; deterministic commands; no generated drift; representative platform evidence.
- Delivery: Linear scope, branch/commit policy, the repository's delivery route and the approvals that route requires, effective branch rules, migration, rollback, and release provenance.
- Operations: idempotency, canary order, observability, recovery, and no destructive mutation without explicit scope.
