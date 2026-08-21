---
name: code-review
description: Orchestrate a read-only, defect-first review of a diff, branch, commit, or pull request through applicable correctness, testing, architecture, Go style, security, production, and documentation specialists. Use for final review before merge or when the user asks for a comprehensive code review.
---

# Code Review Orchestrator

Return a verified set of actionable findings without modifying code, Git state, pull requests, labels, or external systems.

## Establish scope

1. Read applicable `AGENTS.md` files and project skills.
2. Resolve the exact review target. For a branch, prefer its current upstream when available, compute the merge base, and review what would actually merge.
3. Read the change description, plan, issue, or acceptance criteria when available.
4. Inspect the complete diff and enough surrounding code, tests, documentation, and call sites to understand it.
5. Record changed languages, contracts, trust boundaries, runtime paths, and documentation surfaces.

## Route specialist reviews

Use one independent agent per applicable local skill when subagents are available. Pass the exact skill path, review target, applicable project instructions, and raw artifact locations. Do not pass suspected findings or expected answers.

Run in this order, batching only for concurrency limits:

1. `code-review-testing` for behavioral changes; run first so tests establish intent.
2. `code-review-correctness` for every non-mechanical code change.
3. `code-review-architecture` for changes to boundaries, ownership, data flow, APIs, schemas, dependencies, or patterns.
4. `code-review-go-style` when Go files change.
5. `code-review-security` when input, output, files, processes, origins, messages, dependencies, permissions, or private data are touched.
6. `code-review-production` when runtime, concurrency, configuration, packaging, build, release, or operational behavior changes.
7. `code-review-documentation` when public behavior, configuration, CLI/API contracts, architecture, setup, or examples may drift.

If subagents are unavailable, apply the same skills sequentially. Skip an inapplicable specialist with a short reason in working notes, not as report padding.

## Candidate finding contract

Require each specialist to return candidates with:

- priority and imperative title
- changed file and smallest relevant line
- concrete affected scenario or call path
- evidence from code, test, or documented contract
- violated invariant or authoritative rule
- smallest useful fix or missing regression test

## Verify and consolidate

Independently verify every candidate against the diff and surrounding code. Report it only when:

- the change introduced or materially worsened it;
- the affected path is demonstrable;
- it affects correctness, security, production behavior, compatibility, or maintainability in a meaningful way;
- it is discrete and actionable; and
- the author would probably fix it if informed.

Deduplicate by root cause. Prefer the specialist with the most direct evidence. Do not promote speculation, pre-existing issues, intentional behavior, personal preferences, or already-enforced formatting into findings. Report style-only nits only when requested, and label them non-blocking.

Use priorities:

- `P0`: universal critical failure, data loss, or severe security exposure.
- `P1`: urgent defect likely to break an important path.
- `P2`: ordinary actionable defect.
- `P3`: low-impact but meaningful issue; not a personal nit.

## Output

Present findings first, ordered by priority:

`[P2] Imperative finding title — path/to/file.go:42`

Follow with one short paragraph explaining the scenario and evidence. Then give an overall assessment, checks run, and material residual risks or unverified boundaries. If no candidate survives verification, say `No findings.`
