# Governance review checklist

- Contract version and Kaicho authority are explicit; mirrors identify their adopted version.
- Branch and commit examples agree with checker fixtures and hook installation.
- Linear project validation fails closed online and has a documented format-only local mode.
- GitHub configuration preserves protected `main`, least privilege, stable required checks, and no duplicate PR activity trigger.
- Administration scripts resolve exact targets before mutation and provide dry-run/recovery guidance.
- Release/deployment policy covers source identity, immutable artifacts, provenance, approval, health, rollback, and observation.
- Token cost stays bounded: concise routing in `AGENTS.md`, detailed material loaded only on trigger.
