---
name: run-local-quality-checks
description: Discover and run repository quality gates locally through mise, matching CI while selecting the correct macOS or Windows native suite. Use before commits, pushes, pull requests, releases, or when reproducing a CI failure.
---

# Run Local Quality Checks

Run the smallest gate that answers the question, then escalate to the full
platform suite before claiming a change is ready.

## Workflow

1. Read repository guidance and inspect `mise.toml`, hook configuration, and CI
   workflows. Treat those files as the command source of truth.
2. Run `mise install` only if pinned tools are missing.
3. Choose the gate:
   - edit loop: `mise run verify:quick`
   - shared PR checks: `mise run verify`
   - macOS native and E2E: `mise run verify:macos`
   - Windows native and E2E: `mise run verify:windows`
   - hook parity: `mise run git-hooks:run`
4. If the repository uses different task names, map CI steps to existing tasks
   instead of inventing parallel commands.
5. Run checks from the repository root. Do not format or fix code unless the
   user asked for changes; a quality-check request is diagnostic.
6. On failure, preserve the first actionable error, classify it as environment,
   formatting, analysis, unit, native, or E2E, and rerun only the narrow failing
   task after a fix.
7. Before handoff, run the full suite appropriate to the current host and changed
   platform.

## Cross-Platform Rules

- Do not claim Windows native coverage from macOS or macOS native coverage from
  Windows.
- Shared Dart tests may run on either host, but native plugins and desktop E2E
  require their target OS.
- Note any suite that was skipped because its host was unavailable.
- Use the repository's pinned Flutter and tools; avoid a global SDK that happens
  to be on `PATH`.

## Completion Evidence

Summarize each command, result, duration when available, and skipped coverage.
Include concise failure locations without dumping entire logs.
