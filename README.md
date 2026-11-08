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

### Conversational working documents

Use [`write-colleague-notes`](skills/write-colleague-notes/SKILL.md) for role
questions, discovery notes, handoffs, and team updates that should read like a
note to a colleague. It keeps the facts and open questions while removing
report framing, marketing language, repetitive summaries, and em dashes.

```sh
npx skills add NakamaDevs/skills --skill write-colleague-notes --global --agent codex --yes
```

Ask: “Use $write-colleague-notes to rewrite this as a note to the team.”

Use `nakama-write-plain-language` when the main need is Simplified Technical
English. Use `write-colleague-notes` when the main need is a conversational voice
and a less formal document structure.

### Software factory roles

The software factory is the NakamaDevs agent organization: a Director, program
managers, a quality and process engineer, a delivery automation manager, an
allowance manager, and an investigator. Start with
[`nakama-run-software-factory`](skills/nakama-run-software-factory/SKILL.md).
It names every role skill and the deterministic tools in the workspace
repository.

Each role skill ships its Claude Code agent definition at
`assets/claude-agent.md`. The workspace installs them with
`mise run factory:agents`. Codex invokes the skill by name.

```sh
npx skills add NakamaDevs/skills \
  --skill nakama-run-software-factory \
  --skill nakama-direct-software-factory \
  --skill nakama-manage-program \
  --skill nakama-engineer-quality-process \
  --skill nakama-automate-delivery \
  --skill nakama-manage-allowances \
  --skill nakama-investigate-patterns \
  --global --agent codex --agent claude-code --yes
```

### Open Chrome in a specific profile (macOS)

Use [`open-chrome-profile`](skills/open-chrome-profile/SKILL.md) to open a URL in
the Chrome profile signed in with a given email. `-n` is required; without it,
macOS drops the profile flag when Chrome is already running.

```sh
open -na "Google Chrome" --args --profile-email=user@example.com "https://example.com/"
npx skills add NakamaDevs/skills --skill open-chrome-profile --global --agent codex --yes
```

Ask: "Use $open-chrome-profile to open https://example.com/ in the Chrome profile for user@example.com."

### Skill layout

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
