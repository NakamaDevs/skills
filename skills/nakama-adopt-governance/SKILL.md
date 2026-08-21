---
name: nakama-adopt-governance
description: Bootstrap, audit, or refresh a repository against version-pinned Kaicho governance and the NakamaDevs Agent Skills catalog. Use when creating a repository, upgrading governance, repairing missing CODEOWNERS or hooks, or standardizing branch, CI, supply-chain, secret, and agent controls.
---

# Nakama Adopt Governance

1. Inspect the repository before selecting the Kaicho single-repo or monorepo template. Preserve application-specific commands, ownership, platform matrices, and user changes.
2. Create or update `.nakama/repository.toml` from [the context template](assets/repository-context.toml). Pin `skills.revision` to a reviewed `skills` commit.
3. Run `python scripts/validate_repository_context.py .nakama/repository.toml` from this skill, then run the adopted repository's `python scripts/nakama_governance.py agent-contract`.
4. Fetch the required Kaicho governance release separately. Compare its contracts, templates, scripts, hooks, ownership, secret scanner, and CI controls.
5. Apply only compatible changes. Keep organization workflows in the shared skill catalog, detailed policy in the local governance mirror, repository facts in context, and mechanical enforcement in scripts/hooks/CI.
6. Configure GitHub separately: default and protected `main`, PR/code-owner review, required aggregate checks, secret scanning, and push protection. Repository templates do not copy these settings.
7. Install local Git hooks through the repository-owned command, run quick then full validation, and review the final diff with `$nakama-review-change`.
8. Record the governance and skill catalog versions. Also record migration notes, exceptions, and rollback instructions.

Do not duplicate shared skills under `.agents/skills`; Codex does not merge duplicates. Keep only repository-specific skills there.
Install shared skills from an exact `NakamaDevs/skills` revision. Kaicho remains the policy source.
