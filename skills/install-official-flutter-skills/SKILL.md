---
name: install-official-flutter-skills
description: Fetch and install the official Flutter Agent Skills bundle, including its Dart skills, at user scope for Codex. Use when setting up AI-assisted Flutter development or refreshing official best-practice skills.
---

# Install Official Flutter Skills

Install from the Flutter-team-maintained `flutter/agent-plugins` repository. Its
current catalog includes the official Flutter skills and the Dart skills they
depend on.

## Workflow

1. Read [references/sources.md](references/sources.md) and confirm Codex as the
   target.
2. Ensure the repository's pinned Node.js is available with `mise install`.
3. List the source contents before installing:

```sh
npx skills@1.5.17 add flutter/agent-plugins --list
```

4. Ask before the global write. Skills contain instructions and may contain
   executable resources, so treat installation as code installation.
5. Install copied files at user scope. Copies work consistently on Windows,
   where symlink creation can require additional privileges:

```sh
npx skills@1.5.17 add flutter/agent-plugins --skill '*' --global --copy --yes --agent codex
```

The equivalent repository task is:

```sh
mise run skills:flutter:install
```

6. Verify that Codex reports the installed skills. Restart an already-running
   Codex session if it does not refresh its catalog.
7. Report source repositories, CLI version, Codex target, install scope, and
   installed skill names.

## Update Policy

Re-run the pinned installation task after reviewing upstream changes. Do not
silently track an unpinned installer or replace official skills with similarly
named community packages.
