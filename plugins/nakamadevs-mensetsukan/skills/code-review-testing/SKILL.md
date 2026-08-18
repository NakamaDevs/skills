---
name: code-review-testing
description: Review whether changed behavior is protected by valid, maintainable tests and whether available evidence supports a TDD claim. Use first for feature, bug-fix, refactor, schema, API, browser, or other behavioral reviews.
---

# Review Tests

Read tests before implementation so they reveal intended behavior. Review test code as production-quality code.

## Map behavior to evidence

1. Read repository test commands, adjacent test conventions, and the complete changed test functions.
2. List each new or changed observable behavior, error path, state transition, and compatibility promise.
3. Map each behavior to the smallest appropriate unit, integration, contract, browser, end-to-end, or manual check.
4. Confirm assertions observe outcomes rather than incidental implementation calls.
5. Mentally mutate or remove the production change: the test should then fail for the intended reason.
6. Check determinism, isolation, cleanup, diagnostics, fixture realism, and version-specific assumptions.
7. Prefer real local boundaries over mocks when practical. Avoid requiring broad end-to-end tests for behavior a smaller test can prove.

For Mensetsukan, require applicable coverage across Go semantic validation, CLI/server behavior, browser contract behavior, schema/default configuration consistency, and privacy-sensitive presenter/candidate messaging. Rendered UI changes also require documented full- and half-screen manual evidence.

## TDD evidence

A final diff can show test coverage but usually cannot prove test-first order. Accept a TDD claim only when RED output, commit/worklog evidence, or an equivalent trace shows the test failed for the intended reason before the implementation. Otherwise say `test-first history not evidenced`; do not turn that observation alone into a defect.

## Finding gate

Report a finding only when a concrete changed behavior can regress undetected, or when a changed test can pass while the behavior is broken. Cite the changed behavior line if the omission is outside the test diff. Do not demand arbitrary coverage percentages or one test per function.

Return candidates using the orchestrator contract, or `No findings.`
