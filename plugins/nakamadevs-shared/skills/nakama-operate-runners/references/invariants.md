# Runner invariants

- Runner Fleet owns host inventory, labels, bootstrap, service definitions, and recovery procedures.
- Status and validation are read-only; recovery must be idempotent and degradation-aware.
- Labels describe real architecture and capability. Never relabel a host merely to satisfy a queued job.
- Canary one host before fleet-wide rollout and preserve the previous version or configuration for rollback.
- Verify downloads by version plus checksum and keep registration credentials out of persistent configuration when possible.
- A green runner service is insufficient: confirm GitHub visibility and a representative workflow job.
