---
name: code-review-correctness
description: Perform a read-only defect review for concrete regressions in changed behavior, state, error handling, compatibility, and call paths. Use as the baseline specialist for any non-mechanical code review.
---

# Review Correctness

Find behavior that is wrong, not merely different from personal preference.

## Review procedure

1. Read the request, acceptance criteria, project instructions, and relevant architecture.
2. Trace changed entry points through callers, callees, state transitions, and cleanup paths.
3. Compare the implementation with changed tests, schemas, examples, and user-visible behavior.
4. Exercise applicable boundaries: zero/empty, one/many, invalid input, partial input, cancellation, repeated calls, refresh/restart, and failure after partial work.
5. Check compatibility of persisted data, configuration, CLI/API inputs, generated artifacts, and browser navigation.
6. Continue through the entire diff after finding an issue.

For Mensetsukan, pay special attention to schema/runtime/editor/Go-validation drift, generic content, local-storage restoration versus Restart, browser history, message origin/window checks, and interviewer/candidate privacy boundaries.

## Evidence gate

Report a candidate only when the changed line participates in a demonstrable failing scenario. Cite the smallest changed line and name the input, state, or call path that reaches it. Check nearby tests and callers to rule out an existing guard.

Do not report hypothetical edge cases with no reachable path, pre-existing defects, intentional requirement changes, or a missing test without identifying the unprotected behavior.

## Return candidates

Return priority, imperative title, file and line, affected scenario, code/test evidence, violated contract, and the smallest fix or regression test. Return `No findings.` when none qualify.
