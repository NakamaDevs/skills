---
name: setup-self-hosted-ci-runner
description: Provision and register a lean GitHub Actions self-hosted runner on macOS or Windows. Use when preparing a CI host, repairing a runner, aligning runner labels with workflows, or reducing Flutter runner downloads and disk usage.
---

# Set Up a Self-Hosted CI Runner

Provision only what the workflows require, retain expensive SDKs outside
ephemeral checkouts, and prove the host locally before routing CI to it.

## Workflow

1. Read the nearest `AGENTS.md` and inspect `.github/workflows/`, `mise.toml`,
   runner documentation, and existing provisioning scripts.
2. Identify the host OS and architecture. Do not assume x64 on Windows or arm64
   on macOS.
3. Extract every `runs-on` label and make a host-to-label table. Preserve custom
   labels exactly.
4. Inspect the jobs assigned to this host. Install only their direct tooling.
   Prefer repository-owned `mise` setup tasks over global ad-hoc installs.
5. Keep large SDKs in a persistent user or service-account data directory outside
   the checkout. For Flutter, prefer a shallow, revision-pinned checkout and
   selective `flutter precache` for the host target. Do not introduce Docker
   unless a workflow actually uses containers or service containers.
6. Run the repository's local doctor and platform verification tasks.
7. Ask before registering, replacing, or removing a runner. Obtain a fresh,
   short-lived registration token from GitHub and never print, store, or commit it.
8. Register at repository scope unless organization scope is explicitly required.
   Add the exact labels from step 3 and install the runner as a service.
9. Confirm the runner is `Idle`, trigger one safe workflow, and verify that the
   expected host picked up the job.

## Platform Requirements

Read [references/platforms.md](references/platforms.md) before provisioning.

On macOS, verify Xcode selection, license acceptance, and the architectures
required by native dependencies. On Windows, verify Visual Studio's C++ workload,
the Windows SDK, CMake, and architecture-specific compiler components. A Windows
ARM64 host must validate a native ARM64 toolchain rather than silently using x64
emulation.

## Security and Cost Guardrails

- Never run untrusted fork code on a persistent self-hosted runner.
- Keep runner registration tokens and service credentials out of logs.
- Prefer repository-scoped runners and least-privilege service accounts.
- Do not assume GitHub automatically falls back between hosted and self-hosted
  runners.
- Validate billing variables and branch protection separately from host setup.
- Record installed versions, labels, service identity, cache location, disk
  baseline, and verification commands in repository documentation.

## Completion Evidence

Report the host OS/architecture, labels, service status, local verification
results, workflow run URL, elapsed time, and any intentionally omitted platform.
