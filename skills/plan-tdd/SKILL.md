---
name: plan-tdd
description: Make observable behavior and test strategy lead implementation planning. Use whenever planning a feature, bug fix, refactor, contract change, or other behavioral code change; use after interface-intent discovery for visual work and before writing implementation tasks.
---

# Plan with TDD

Make tests the first executable work in a plan. Planning describes expected RED evidence; only an actual test run can establish that RED occurred.

## Discover the test contract

1. Read `AGENTS.md`, the request or specification, and relevant architecture and configuration docs.
2. Discover repository-owned test commands and conventions from task runners, CI, adjacent tests, and contribution docs. Do not invent generic commands.
3. Identify observable behavior, invariants, error paths, compatibility promises, and user-visible states.
4. For an existing bug, require a minimal reproduction or characterization test before the fix.
5. For a refactor, characterize behavior that must remain unchanged before moving structure.

For Mensetsukan, use the smallest applicable layers: Go tests for CLI/server/semantic behavior, browser contract tests for embedded runtime behavior, and full- and half-screen manual checks for rendered editor, presenter, and candidate flows. `mise run check` remains the final repository gate.

## Build the test matrix

For each behavior, record:

| Field | Required content |
| --- | --- |
| Behavior | User- or caller-observable outcome |
| Risk | Regression or failure the test prevents |
| Layer | Unit, integration, contract, browser, end-to-end, or manual |
| Fixture/setup | Smallest deterministic setup |
| RED evidence | Expected failure and why it proves the missing behavior |
| GREEN evidence | Exact focused command and expected passing result |
| Refactor guard | Behavior that must stay green while structure changes |

Prefer behavior assertions over implementation interactions. Prefer real implementations, then fakes, then stubs; use mocks only at boundaries that cannot be made deterministic or local.

## Order implementation work

For each coherent behavior, plan these steps in order:

1. Add one focused test.
2. Run it and confirm it fails for the intended missing behavior, not for setup or syntax.
3. Add the minimum production change that can pass it.
4. Run the focused test and relevant nearby tests.
5. Refactor only while tests remain green.
6. Run the complete project gate before handoff.

Do not group all tests at the end. Do not claim TDD history from a finished diff alone. If RED output was not observed, label it `not yet evidenced`.

## Exceptions

Mark TDD not applicable only for a change with no behavioral effect, such as prose-only documentation or a mechanical generated artifact. State the reason and retain any applicable validation such as link, schema, format, or generation checks.

## Output

Place the test matrix before implementation steps. Include exact test locations and commands when discoverable, expected RED/GREEN evidence, manual verification boundaries, and unresolved testability risks.
