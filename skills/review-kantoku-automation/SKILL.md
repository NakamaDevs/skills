---
name: review-kantoku-automation
description: Review Kantoku shell automation, GitHub Actions, runner selection, packaging, semantic versions, releases, and deployment. Use when a diff touches scripts, .github, mise.toml, release assets, installers, or operational configuration.
---

# Review Kantoku automation

1. Read `AGENTS.md`, the governance copy, Linear issue, final diff, and affected release/operations docs.
2. Check shell quoting, idempotency, partial failure, destructive targets, portability, and safe credential handling.
3. Check Actions permissions, pinned versions, expression interpolation, caches, matrices, concurrency, triggers, artifacts, and secret boundaries.
4. Verify Semantic Versioning, source commit, release notes, signing/notarization, immutable checksums, and provenance agree.
5. Require a dry run, promotion/approval boundary, compatibility order, health signal, rollback, and observation for release/deployment changes.
6. Run actionlint and the relevant repository-owned packaging/release validation.
7. Report findings by severity with operational impact and fix; otherwise state no findings and residual risk.
