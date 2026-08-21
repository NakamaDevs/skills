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

## External skills

This catalog contains skills maintained by NakamaDevs. It does not copy
third-party skills. Install Flutter, Dart, and Herdr skills from their upstream
projects. Install the forked skill packs from NakamaDevs. Select a reviewed,
full commit SHA before an automated or repeatable installation.

| Domain | Upstream | Install command |
| --- | --- | --- |
| Flutter | [`flutter/agent-plugins`](https://github.com/flutter/agent-plugins) and [Flutter agent-skills documentation](https://docs.flutter.dev/ai/agent-skills) | `npx skills add https://github.com/flutter/agent-plugins/tree/<FULL_COMMIT_SHA> --skill '*' --agent universal --yes` |
| Dart | [`dart-lang/skills`](https://github.com/dart-lang/skills) | `npx skills add https://github.com/dart-lang/skills/tree/<FULL_COMMIT_SHA> --skill '*' --agent universal --yes` |
| Herdr | [`herdrdev/herdr`](https://github.com/herdrdev/herdr) | `npx skills add https://github.com/herdrdev/herdr/tree/<FULL_COMMIT_SHA> --skill herdr --agent universal --yes` |

| Skill pack | NakamaDevs fork | Install command |
| --- | --- | --- |
| Aspire | [`NakamaDevs/aspire-skills`](https://github.com/NakamaDevs/aspire-skills) | `npx skills add https://github.com/NakamaDevs/aspire-skills/tree/<FULL_COMMIT_SHA> --skill '*' --agent universal --yes` |
| HyperFrames | [`NakamaDevs/hyperframes`](https://github.com/NakamaDevs/hyperframes) | `npx skills add https://github.com/NakamaDevs/hyperframes/tree/<FULL_COMMIT_SHA> --skill '*' --agent universal --yes` |
| HTMX | [`NakamaDevs/htmx-skills`](https://github.com/NakamaDevs/htmx-skills) | `npx skills add https://github.com/NakamaDevs/htmx-skills/tree/<FULL_COMMIT_SHA> --skill '*' --agent universal --yes` |
| OpenPencil | [`NakamaDevs/open-pencil-skills`](https://github.com/NakamaDevs/open-pencil-skills) | `npx skills add https://github.com/NakamaDevs/open-pencil-skills/tree/<FULL_COMMIT_SHA> --skill '*' --agent universal --yes` |
| Playwright CLI | [`NakamaDevs/playwright-cli`](https://github.com/NakamaDevs/playwright-cli) | `npx skills add https://github.com/NakamaDevs/playwright-cli/tree/<FULL_COMMIT_SHA> --skill playwright-cli --agent universal --yes` |
| Orchestrate | [`NakamaDevs/codex-skills`](https://github.com/NakamaDevs/codex-skills) | `npx skills add https://github.com/NakamaDevs/codex-skills/tree/<FULL_COMMIT_SHA> --skill orchestrate --agent universal --yes` |

Replace `<FULL_COMMIT_SHA>` with a reviewed 40-character commit SHA. Record the
source and SHA in the consumer repository. Do not use a local path in locks or
metadata.

Fork an external skill only when NakamaDevs must modify it. The fork must be
public. Record its upstream URL, upstream SHA, license, and local differences
in [SOURCES.md](SOURCES.md). Keep the upstream license with the forked files.

## Policy

Kaicho defines the organization policy for skill creation and installation.
This repository contains the reusable skill content.
