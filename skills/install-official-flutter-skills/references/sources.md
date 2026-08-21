# Official sources and discovery

The Flutter team documents Agent Skills at:

- https://docs.flutter.dev/ai/agent-skills
- https://github.com/flutter/agent-plugins
- https://github.com/dart-lang/skills

The `flutter` and `dart-lang` organizations own the repositories. The old
`flutter/skills` name has moved to `flutter/agent-plugins`. Install Flutter and
Dart skills from their respective upstream repositories. Do not copy them into
the NakamaDevs catalog. Use a reviewed full commit SHA for repeatable installs.

Project-level portable skills use `.agents/skills/<name>/SKILL.md`. The `skills`
CLI can also install at the Codex user-level location:

- Codex: `~/.codex/skills`

Use `--copy` for predictable behavior across macOS and Windows. The installer
version is pinned in commands so a future CLI change does not silently alter
the destination or link behavior.
