---
name: nakama-review-change
description: Review a NakamaDevs change against organization-wide correctness, security, quality, supply-chain, secret, CI, release, and operational gates, then route to repository-specific review skills. Use for pull-request review, pre-push review, or governance compliance review.
---

# Nakama Review Change

1. Read `.nakama/repository.toml`, applicable `AGENTS.md`, the local governance mirror, linked Linear issue, and the final base/head diff.
2. Load [the baseline checklist](references/baseline.md). Invoke only the affected repository-specific review skills named by `review.router` or `review.additional`.
3. Verify behavior and failure modes before style. Inspect permissions, data handling, concurrency, compatibility, migrations, rollback, and missing tests.
4. For dependencies, workflows, installers, or generated locks, enforce the seven-day routine quarantine, immutable resolution, full-SHA Actions, checksum/provenance review, and least privilege.
5. For credentials or sensitive configuration, verify staged and complete-history scans, redaction, narrow allowlists, and revocation-first response.
6. Confirm local commands map to CI, required aggregate jobs are stable, duplicate events do not rerun an unchanged commit, and platform omissions are explicit.
7. Report findings ordered by severity with a tight location, concrete failure mode, impact, and practical fix. Avoid speculative or stylistic findings.

If no actionable findings remain, say so and identify residual risk, untested platforms, or evidence you could not verify. Passing automation never replaces independent review.
