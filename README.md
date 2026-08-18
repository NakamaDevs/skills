# NakamaDevs Codex skills

This repository is the public Codex skill catalog for NakamaDevs.
Kaicho remains the source for organization policy.
This repository contains reusable Codex workflows only.

## Install the marketplace

Run this command in Codex CLI or the Codex desktop app:

```text
codex plugin marketplace add NakamaDevs/codex-skills --ref main
```

Open `/plugins` and install the required plugin.
Start a new Codex session after installation.
Codex IDE extensions do not support plugins at this time.
See the official [plugin documentation](https://developers.openai.com/plugins/build/plugins).
See the official [skill documentation](https://learn.chatgpt.com/docs/build-skills).

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

## Repository use

A repository must not copy these skills.
Install the marketplace once, then install the required plugin.
Repository `AGENTS.md` files can name installed skills with `$skill-name`.
Repository instructions must not depend on an uninstalled skill.

## Safety

Imported skills have pinned source revisions in [SOURCES.md](SOURCES.md).
The catalog rejects missing metadata and non-Codex tool declarations.
Skills that change systems require explicit invocation.
Run `mise run verify` before each pull request.

## License

Each imported skill retains its source license.
Embedded license files apply to their skill directories.
See [SOURCES.md](SOURCES.md) for provenance.
