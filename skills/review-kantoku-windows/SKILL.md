---
name: review-kantoku-windows
description: Review Kantoku Windows 10/11 x64 tray, runner-service control, .NET packaging, installer, and Windows x64 CI changes. Use for files under windows_tray, Windows release assets, or workflows selecting nakama-windows-x64.
---

# Review Kantoku Windows

Review only the final Windows-related diff unless a cross-stack contract requires wider context.

1. Read `AGENTS.md`, `.governance/engineering-v2.md`, `.governance/privacy.md`, and the affected Windows files.
2. Confirm every Kantoku Windows job selects `nakama-windows-x64`. Reject use of `nakama-windows-arm64`, GitHub-hosted runners, or an unscoped `self-hosted` label.
3. Require an explicit rollout guard until an x64 runner is provisioned and online.
4. Keep the tray local and credential-free. It may inspect or control only allowlisted `actions.runner.NakamaDevs.*` Windows services and must not accept shell text.
5. Check process calls use an executable plus structured argument list, service names are validated, failures are visible, and UI/timer resources are disposed.
6. Require the exact .NET SDK pin, no unreviewed NuGet dependency, a self-contained `win-x64` single executable, PE x64 validation, deterministic archive contents, and SHA-256 evidence.
7. Keep installation current-user scoped, versioned, atomic, and rollback-capable. Do not store secrets or broadly delete files.
8. Run the package-free contract tests, installer payload verification, Python compilation, Actionlint, the skill validator, and the applicable aggregate checks. Do not dispatch ARM64 tests.
9. Report findings by severity with file and line evidence. If there are none, say so and list residual platform validation still awaiting the Windows x64 host.
