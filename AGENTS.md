# Skills repository guide

This repository contains private agent skills and plugin metadata.
Codex and Claude Code both install from it.
Kaicho contains organization policy.
Do not copy policy into this repository.

Keep each skill in one plugin directory.
Each skill must contain `SKILL.md` and `agents/openai.yaml`.
Each plugin must contain `.codex-plugin/plugin.json` and `.claude-plugin/plugin.json`.
Keep the name, version, and description equal in both manifests.
List every plugin in both marketplace files.

Use Codex tool names and Codex invocation syntax in `SKILL.md`.
Do not add tool declarations for one tool only.

Record every imported source and exact revision in `SOURCES.md`.
Keep third-party licenses with imported content.
Require explicit invocation for installation, deployment, external writes, and paid services.

Run `mise run verify` before each pull request.
Use `$resolve-pr-review-threads` before merge.
