<!-- kaicho-delivery-v2.1 -->
## NakamaDevs delivery policy — v2.1

Use [.nakama/kaicho/delivery-profiles.md](.nakama/kaicho/delivery-profiles.md)
and [.nakama/delivery.json](.nakama/delivery.json). This owner-approved policy
replaces older PR, approval, branch-namespace and delivery-gate requirements
for the routes it defines, including instructions elsewhere in this repository.
Repository mode: **solo**. Solo work may commit and push directly to the
default branch without a PR. Collaborative work retains normal CI/CD and approvals;
explicit owner override and scoped agent delivery remain available.
Every delivered commit includes `Refs TEAM-123` or `Fixes TEAM-123` in its body.
Verify the real Linear issue and project through the connected integration.
After push, verify the link or attach the immutable commit URL to Linear.
Never rewrite published history merely to add tracking metadata.
Keep existing published branches and other contributors' work. New branches use
`type/TEAM-123-description`; no username or agent namespace. Run focused checks
and record actual results. Never claim skipped CI passed. Do not create a PR
solely for policy adoption. Keep application, secret, runner and deployment
controls except for a specifically authorized owner override.
Run `python3 .nakama/kaicho_delivery.py self-test` for delivery checks.
Install the repository's configured hooks (for example `prek install --hook-type commit-msg`).
Pinned source: Kaicho `91ec23b858c2d6aa74a987901592c7493259e89d`. Tracking: NAK-946.
<!-- /kaicho-delivery-v2.1 -->

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
