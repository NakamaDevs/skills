# Skill sources

This catalog preserves the source revision for each migration.
NakamaDevs owns the imported organization repositories.
Third-party license files remain beside their imported content.

## External skill sources

This repository does not copy third-party skill content. Consumers must select
and record a reviewed full commit SHA before installation.

| Domain | Upstream | License | Local content |
| --- | --- | --- | --- |
| Flutter | [`flutter/agent-plugins`](https://github.com/flutter/agent-plugins) | BSD-3-Clause | None |
| Dart | [`dart-lang/skills`](https://github.com/dart-lang/skills) | BSD-3-Clause | None |
| Herdr | [`herdrdev/herdr`](https://github.com/herdrdev/herdr) | See upstream repository | None |

Flutter installation guidance is available at
<https://docs.flutter.dev/ai/agent-skills>.

| Fork | Upstream | Fork revision | License | Replaced local skills |
| --- | --- | --- | --- | --- |
| [`NakamaDevs/aspire-skills`](https://github.com/NakamaDevs/aspire-skills) | [`microsoft/aspire-skills`](https://github.com/microsoft/aspire-skills) | `1e0cc36c1d8131ba16a8d72b0ab011168bee7b13` | MIT | `aspire`, `aspire-deployment`, `aspire-init`, `aspire-monitoring`, `aspire-orchestration`, `aspireify` |
| [`NakamaDevs/hyperframes`](https://github.com/NakamaDevs/hyperframes) | [`heygen-com/hyperframes`](https://github.com/heygen-com/hyperframes) | `41af866bcb453357e17fd1c19cba2f7ed080a89a` | Apache-2.0 | `general-video`, `hyperframes`, `hyperframes-animation`, `hyperframes-audio`, `hyperframes-cli`, `hyperframes-core`, `hyperframes-creative`, `hyperframes-keyframes`, `hyperframes-registry`, `media-use` |
| [`NakamaDevs/htmx-skills`](https://github.com/NakamaDevs/htmx-skills) | [`piyiotisk/htmx-skills`](https://github.com/piyiotisk/htmx-skills) | `29190c67cdef4a8f1d2c9e5ac7ff0e4fa9c746e6` | MIT | `htmx` |
| [`NakamaDevs/open-pencil-skills`](https://github.com/NakamaDevs/open-pencil-skills) | [`open-pencil/skills`](https://github.com/open-pencil/skills) | `623927958f277b0d8810a2582a38ae24409f7577` | MIT | `open-pencil` |
| [`NakamaDevs/playwright-cli`](https://github.com/NakamaDevs/playwright-cli) | [`microsoft/playwright-cli`](https://github.com/microsoft/playwright-cli) | `2f85a94b7b885dbf4a5d34462f253a8746a690c9` | Apache-2.0 | `playwright-cli` |
| [`NakamaDevs/codex-skills`](https://github.com/NakamaDevs/codex-skills) | [`provencher/codex-skills`](https://github.com/provencher/codex-skills) | `8aa6c42b73781c905c55f8a1253a18127079ac21` | MIT | `orchestrate` |

The catalog removed the listed local copies. Fork revisions do not prove that
they match the removed snapshots. Compare before reintroducing a local change.

## Fork requirements

Create a public `NakamaDevs` fork only when a local modification is required.
Add one row for every fork with its upstream URL, full upstream commit SHA,
license file path, affected catalog paths, and a concise description of local
differences. Keep the upstream license beside the copied files.

| Source | Revision | Imported content |
| --- | --- | --- |
| `NakamaDevs/Amanuensis` | `285cf091c8f19949187b34f2fedfe7380aa00c00` | Amanuensis skills |
| `NakamaDevs/Kaicho` | `691f6de7b011cc412a088a30098608ca1c8e63d3` | Shared skills and Kaicho review |
| `NakamaDevs/docs` | `cf0c54e75ab6273caa9fc93106fcd75f73cb8537` | Documentation review |
| `NakamaDevs/kantoku` | `71df67938ce059d490d7e696a6e9b314344387ec` | Kantoku review skills |
| `NakamaDevs/stingray` | `85453ec06bc2f78291b27fccaffc85bd9e02ef8b` | Playwright CLI skill |
| `NakamaDevs/kenkyu` | `b7aa15672857881b53cd1aba41174715614ac10e` | Technology research skill |
| `NakamaDevs/mensetsukan` | `6d19dd8467da88acaef9a3cfc0193a4f070543b5` | Engineering and media skills |
| `NakamaDevs/runner-fleet` | `4aac877097e4607acf15d957ed184e4e66cf9cde` | Runner fleet skills |
Migration changes only adapt integrations to Codex.
They also add Codex interface metadata and explicit invocation controls.
