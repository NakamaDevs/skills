---
name: validate-runner-fleet-python
description: Validate Runner Fleet Python automation with pinned Ruff formatting, Ruff linting, and unit tests through Mise. Use after changing Python scripts, Python tests, rollout planning, host or runner manifests consumed by Python, Python tool versions, or before a runner fleet commit or rollout.
---

# Validate Runner Fleet Python

Use the repository's pinned Mise environment; do not substitute globally
installed Python or Ruff versions when reporting gate results.

## Run the gate

1. Read `pyproject.toml`, `mise.toml`, and the changed Python and test files.
2. Install the pinned tools when needed:

```sh
mise install
```

3. Run the non-mutating quality gate:

```sh
mise run python:quality
```

This must run Ruff format checking, Ruff linting, and Python unit tests. Do not
skip a failed stage because a later command passes.

## Repair failures

For formatting-only failures, run:

```sh
mise run python:format
mise run python:quality
```

For lint or test failures, diagnose and patch the cause, then repeat the whole
gate. Do not weaken Ruff rules, delete assertions, or exclude files merely to
obtain green output. Add a regression test for every corrected rollout bug
that can be reproduced without a live runner.

## Full validation

After the Python gate passes, run `mise run validate` when the change affects
fleet manifests, bootstrap behavior, Actions, services, or rollout. Report the
exact commands, pass/fail state, and anything that still requires a native host
or live GitHub verification.
