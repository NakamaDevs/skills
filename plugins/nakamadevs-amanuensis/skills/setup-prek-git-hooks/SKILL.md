---
name: setup-prek-git-hooks
description: Set up cross-platform Git quality hooks with prek and mise. Use when adding pre-commit or pre-push gates, replacing another hook manager, repairing local hooks, or keeping local checks aligned with CI on macOS and Windows.
---

# Set Up Prek Git Hooks

Use `prek` as a fast, Python-compatible pre-commit framework implementation and
pin it through `mise` so contributors receive the same version.

## Workflow

1. Read repository guidance and inspect `mise.toml`, `.pre-commit-config.yaml`,
   `.git/hooks`, and the CI quality commands.
2. Preserve existing user hooks. If migration would overwrite a non-managed
   hook, stop and explain the conflict.
3. If `prek` is not pinned, add it to the repository's `mise` tools.
4. Create or update `.pre-commit-config.yaml`:
   - use `language: system` for repository-owned `mise` tasks;
   - make fast, non-mutating checks pre-commit;
   - move complete tests to pre-push;
   - set `pass_filenames: false` for whole-project commands;
   - keep hook commands identical to documented local or CI entry points.
5. Provide repository tasks with stable names: `git-hooks:install`,
   `git-hooks:run`, `git-hooks:uninstall`, and optionally `git-hooks:clean`.
6. Run `mise install`, then install and prepare both hooks:

```sh
mise run git-hooks:install
```

7. Verify all tracked files without creating a commit:

```sh
mise run git-hooks:run
```

8. Inspect `.git/hooks/pre-commit` and `.git/hooks/pre-push` only to confirm they
   are prek-managed. Do not commit `.git/hooks`.

## Gate Design

- Pre-commit should finish quickly and must not rewrite files unexpectedly.
- Pre-push may run shared tests but should avoid platform E2E suites unless the
  repository explicitly chooses that cost.
- CI remains authoritative; hooks are an earlier feedback layer.
- Use POSIX-neutral commands or paired PowerShell/POSIX repository tasks.
- Never bypass a failing hook merely to finish the setup.

## Completion Evidence

Report the pinned prek version, installed hook types, exact tasks each stage
runs, and the result of the all-files verification.
