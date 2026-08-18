# Codex skills repository guide

This repository contains private Codex skills and plugin metadata.
Kaicho contains organization policy.
Do not copy policy into this repository.

Keep each skill in one plugin directory.
Each skill must contain `SKILL.md` and `agents/openai.yaml`.
Use Codex tool names and Codex invocation syntax.
Do not add Claude-specific tool declarations.

Record every imported source and exact revision in `SOURCES.md`.
Keep third-party licenses with imported content.
Require explicit invocation for installation, deployment, external writes, and paid services.

Run `mise run verify` before each pull request.
Use `$resolve-pr-review-threads` before merge.
