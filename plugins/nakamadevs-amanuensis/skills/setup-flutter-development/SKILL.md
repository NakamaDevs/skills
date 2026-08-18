---
name: setup-flutter-development
description: Provision or repair a Flutter workstation with mise on macOS or Windows for desktop, Android, and web targets. Use for first-time local setup, onboarding, Flutter doctor failures, IDE setup, or adding a new target platform.
---

# Set Up Flutter Development

Provision the SDK version chosen by the repository, then install only the native
toolchains required by the user's target platforms.

## Workflow

1. Ask which targets are required: macOS, Windows, Android, web, or iOS.
2. Read repository guidance, `.flutter-version`, `mise.toml`, and setup scripts.
3. Install Git and `mise` if missing. Ask before installing GUI applications or
   accepting licenses.
4. Prefer the repository's Flutter provisioning task:

```sh
mise install
mise run setup
```

If the repository owns a shallow or selective Flutter installer, use it. Do not
replace it with `mise install flutter` or a second global SDK.
5. Follow the target matrix in [references/platforms.md](references/platforms.md).
6. Configure Android Studio to use the repository-managed Flutter SDK and install
   the Dart and Flutter IDE plugins.
7. Run the repository doctor task or `flutter doctor -v`. Resolve errors only for
   selected targets; warnings for intentionally unsupported targets are not setup
   failures.
8. Run `flutter devices`, fetch project dependencies, and execute one debug build
   or test for each selected target.

## Architecture and Storage

- Detect arm64 versus x64; do not install emulated tooling by default.
- Keep SDKs and caches out of the Git checkout.
- On Windows, favor short SDK paths and architecture-matched Visual Studio
  components.
- Native desktop builds are host-specific. macOS cannot build the Windows
  desktop runner, and Windows cannot build the macOS desktop runner.

## Completion Evidence

Report Flutter and Dart versions, SDK path, host architecture, selected targets,
`flutter doctor -v` status, visible devices, and one verified command per target.
