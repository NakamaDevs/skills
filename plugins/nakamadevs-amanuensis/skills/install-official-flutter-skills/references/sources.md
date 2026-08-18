# Official sources and discovery

The Flutter team documents Agent Skills at:

- https://docs.flutter.dev/ai/agent-skills
- https://github.com/flutter/agent-plugins
- https://github.com/dart-lang/skills

The `flutter` and `dart-lang` organizations own the repositories. The old
`flutter/skills` name has moved to `flutter/agent-plugins`. The Flutter plugin
catalog currently bundles the Dart skills, so the default workflow installs the
Flutter repository once. Use `dart-lang/skills` separately only for a Dart-only
environment.

Project-level portable skills use `.agents/skills/<name>/SKILL.md`. The `skills`
CLI can also install at the Codex user-level location:

- Codex: `~/.codex/skills`

Use `--copy` for predictable behavior across macOS and Windows. The installer
version is pinned in commands so a future CLI change does not silently alter
the destination or link behavior.
