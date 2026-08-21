---
name: write-first-tests
description: "Write, review, diagnose, or refactor tests using the FIRST properties: fast, independent, repeatable, self-validating, and timely. Use for flaky or slow suites, TDD work, fixture design, test-quality review, and commit or CI feedback gates."
---

# Write FIRST tests

Apply FIRST to every focused automated test:

- **Fast:** keep the default feedback loop short; move expensive confidence to an explicit higher layer.
- **Independent:** isolate state and order; each test creates and owns its fixture.
- **Repeatable:** control time, randomness, locale, ports, files, network, and external services.
- **Self-validating:** assert pass or fail without human inspection; artifacts explain failures but do not decide them.
- **Timely:** write the test before or with the behavior, and observe the intended RED failure before implementation when practicing TDD.

## Review procedure

1. Run the narrow test alone, in a batch, and in a different order when supported.
2. Identify uncontrolled inputs and shared mutable state.
3. Replace sleeps with observable readiness and bounded polling.
4. Prefer real local collaborators at integration seams; use fakes for unavailable or nondeterministic boundaries.
5. Make assertions describe externally visible behavior.
6. Keep cleanup scoped and recoverable; use test-owned temporary directories.
7. Measure and report the runtime budget.

Read [references/first.md](references/first.md) for source definitions and practical failure smells.

## Output

Report each FIRST property as pass, fail, or unverified; cite the offending test; propose the smallest change; and give an exact repeatability command.
