# NakamaDevs skill catalog

This repository is the private skill catalog for NakamaDevs.
Codex and Claude Code both install from it.
Kaicho remains the source for organization policy.
This repository contains reusable agent workflows only.

## Install the marketplace in Codex

Run this command in Codex CLI or the Codex desktop app:

```text
codex plugin marketplace add NakamaDevs/codex-skills --ref main
```

Open `/plugins` and install the required plugin.
Start a new Codex session after installation.
Codex IDE extensions do not support plugins at this time.
See the official [plugin documentation](https://developers.openai.com/plugins/build/plugins).
See the official [skill documentation](https://learn.chatgpt.com/docs/build-skills).

## Install the marketplace in Claude Code

Run these commands in Claude Code:

```text
/plugin marketplace add NakamaDevs/codex-skills
/plugin install nakamadevs-shared@nakamadevs
```

Install other plugins in the same way.
Start a new Claude Code session after installation.
See the official [plugin reference](https://code.claude.com/docs/en/plugins-reference).

## Plugin groups

| Plugin | Purpose |
| --- | --- |
| `nakamadevs-shared` | Shared delivery, governance, review, writing, and orchestration workflows |
| `nakamadevs-amanuensis` | Amanuensis development and review workflows |
| `nakamadevs-kaicho` | Kaicho governance review |
| `nakamadevs-docs` | Organization documentation review |
| `nakamadevs-kantoku` | Kantoku development review |
| `nakamadevs-stingray` | Playwright browser automation |
| `nakamadevs-kenkyu` | Emerging technology research |
| `nakamadevs-mensetsukan` | Engineering, testing, browser, design, and media workflows |
| `nakamadevs-runner-fleet` | Runner fleet review and rollout workflows |

## One skill, two tools

Each skill has one `SKILL.md` file.
Codex and Claude Code both read it.
Only the plugin metadata differs:

| Part | Codex | Claude Code |
| --- | --- | --- |
| Marketplace | `.agents/plugins/marketplace.json` | `.claude-plugin/marketplace.json` |
| Plugin manifest | `<plugin>/.codex-plugin/plugin.json` | `<plugin>/.claude-plugin/plugin.json` |
| Skills path | `"skills": "./skills/"` | discovered from `skills/` |
| Skill metadata | `skills/<name>/agents/openai.yaml` | not used |

Do not copy a skill to add a tool.
Add the metadata for that tool instead.

## Repository use

A repository must not copy these skills.
Install the marketplace once, then install the required plugin.
Repository `AGENTS.md` files can name installed skills with `$skill-name`.
Claude Code invokes the same skill with `/plugin-name:skill-name`.
Repository instructions must not depend on an uninstalled skill.

## Safety

Imported skills have pinned source revisions in [SOURCES.md](SOURCES.md).
The catalog rejects missing metadata and non-portable tool declarations.
Skills that change systems require explicit invocation in Codex.
Claude Code has no equivalent catalog control at this time.
Run `mise run verify` before each pull request.

## License

Each imported skill retains its source license.
Embedded license files apply to their skill directories.
See [SOURCES.md](SOURCES.md) for provenance.
