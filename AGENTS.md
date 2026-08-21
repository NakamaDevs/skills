# Skills repository guide

This repository contains reusable Agent Skills for NakamaDevs.
Kaicho contains organization policy.
Do not copy policy into this repository.

Keep each skill in `skills/<name>/`.
Each skill must contain `SKILL.md` with `name` and `description` frontmatter.
Use kebab-case skill names.
Keep optional scripts, references, and assets inside the skill directory.

`skills/` contains only skills maintained by NakamaDevs. Do not vendor a
third-party skill there. Reference its upstream directly. Create a public
`NakamaDevs` fork only when a local change is necessary. Record the upstream,
exact upstream revision, license, and local differences for every fork.

Use portable Agent Skills instructions.
Use Codex tool names and invocation syntax only when the skill targets Codex.
Require explicit invocation for installation, deployment, external writes, and paid services.

Record every imported source and exact revision in `SOURCES.md`.
Keep third-party licenses with imported content.

Install skills with `npx skills add NakamaDevs/skills`.
Run `npx skills add NakamaDevs/skills --list` to inspect the catalog.

Run `mise run verify` before each pull request.
