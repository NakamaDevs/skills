---
name: apply-test-pyramid
description: Design, review, or rebalance automated test coverage across unit, integration, contract, browser, and end-to-end layers. Use for test strategy, coverage gaps, regression planning, CI gates, or deciding which layer should own a behavior.
---

# Apply the test pyramid

Choose the lowest layer that proves the behavior with adequate confidence. Keep many fast unit tests, fewer boundary-focused integration tests, and a small set of high-value end-to-end journeys.

## Build the risk map

1. Read repository test commands, architecture, and the behavior under change.
2. List observable risks and the boundary at which each can fail.
3. Assign each risk to one primary layer; do not repeat every edge case at higher layers.
4. Add a higher-layer test only when lower layers cannot prove wiring, browser behavior, or the complete user outcome.

Use this decision table:

| Layer | Prove | Avoid |
| --- | --- | --- |
| Unit | pure logic, parsing, state transitions, error mapping | files, networks, browsers, timing |
| Integration | real component seams, schemas, HTTP handlers, databases, processes | duplicating all unit cases |
| Contract | stable API, file, schema, or HTML/runtime agreements | implementation details |
| End-to-end | a few critical user journeys through the real stack | exhaustive permutations |
| Exploratory/manual | usability, visual judgment, unexpected paths | claims of repeatable regression coverage |

## Require evidence

- Record the test command, fixture, expected failure, and passing evidence.
- Quarantine or fix flakes; never normalize retries as proof.
- Preserve failure artifacts for broad-stack tests: logs, screenshot, trace, URL, and seed data.
- Run focused layers during development and the repository-owned complete gate before handoff.

For definitions, economics, and exceptions, read [references/test-pyramid.md](references/test-pyramid.md).

## Output

Return a risk-to-layer matrix, exact commands, critical E2E journeys, missing seams, runtime budget, and any unverified boundary.
