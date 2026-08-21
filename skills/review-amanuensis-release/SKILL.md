---
name: review-amanuensis-release
description: Review Amanuensis GitHub Actions, platform matrices, Flutter toolchain, packaging, Semantic Versioning, artifacts, releases, and deployment. Use when a diff touches .github, mise.toml, Flutter revision files, build metadata, signing, packaging, or release automation.
---

# Review Amanuensis release

1. Read `AGENTS.md`, the governance copy, Linear issue, final diff, and release workflow.
2. Check Actions permissions, intentional versions, expression safety, caches, concurrency, triggers, and secret isolation.
3. Verify matrices cover supported Flutter, macOS architecture, Windows x64/ARM64, with explicit rationale for skips.
4. Reconcile semantic version, generated metadata, source commit, signing/notarization, checksums, provenance, and notes.
5. Ensure artifacts are immutable and promoted after verification; define approval, smoke/health evidence, rollback, and observation.
6. Run actionlint and affected build/package dry runs.
7. Report findings by severity with platform/operational impact; otherwise state no findings and residual risk.
