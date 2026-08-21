# NakamaDevs Agent Skills

This repository contains reusable Agent Skills for NakamaDevs.
It uses the open Vercel Skills ecosystem.

## Install

List available skills:

```sh
npx skills add NakamaDevs/skills --list
```

Install all skills for Codex:

```sh
npx skills add NakamaDevs/skills --skill '*' --global --agent codex --yes
```

Install selected skills for several agents:

```sh
npx skills add NakamaDevs/skills \
  --skill nakama-review-change \
  --skill nakama-write-plain-language \
  --global \
  --agent codex \
  --agent claude-code \
  --yes
```

The workspace root provides the same workflow:

```sh
mise run install:skills
```

The default task installs all skills globally for Codex.
Set `SKILLS` to a space-separated list to install selected skills.
Set `SKILLS_AGENTS` to a space-separated agent list.

## Structure

Every skill uses this layout:

```text
skills/
  skill-name/
    SKILL.md
    agents/       optional agent metadata
    scripts/      optional executable helpers
    references/   optional supporting material
    assets/       optional templates or media
```

`SKILL.md` must start with YAML frontmatter.
The frontmatter must contain a unique lowercase `name` and a `description`.

The Vercel CLI discovers skills in `skills/<name>/SKILL.md`.
The CLI installs project skills into agent-specific project directories.
The CLI installs global skills into agent-specific user directories.

## Development

Run the catalog checks:

```sh
mise run verify:quick
```

Run all checks:

```sh
mise run verify
```

Record imported sources and exact revisions in [SOURCES.md](SOURCES.md).
Keep third-party licenses beside imported content.

## Policy

Kaicho defines the organization policy for skill creation and installation.
This repository contains the reusable skill content.
