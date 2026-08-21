---
name: code-review-go-style
description: Review changed Go code against repository conventions and authoritative Google and Go style guidance while separating enforceable rules, readability defects, and optional nits. Use whenever a reviewed change contains Go source.
---

# Review Go Style

Apply sources in this precedence order:

1. Repository `AGENTS.md` and explicit local conventions.
2. Compiler behavior plus pinned `gofmt`, `go vet`, Staticcheck, and repository checks.
3. Google Go Style Guide: <https://google.github.io/styleguide/go/guide> — normative and canonical.
4. Google Go Style Decisions: <https://google.github.io/styleguide/go/decisions> — normative, non-canonical, and subordinate to the Guide.
5. Google Go Style Best Practices: <https://google.github.io/styleguide/go/best-practices> — auxiliary, contextual guidance.
6. Official Go guidance: <https://go.dev/doc/effective_go> and <https://go.dev/wiki/CodeReviewComments>.
7. Local consistency only where higher-priority sources are silent.

Do not import a community checklist rule that conflicts with this hierarchy. In particular, do not invent a rigid line-length limit; the Google Guide prefers refactoring and allows a line to remain long when already as short as practical.

## Review procedure

1. Confirm the module Go version and repository-owned commands.
2. Run non-mutating formatting and static checks when authorized and practical.
3. Inspect only applicable decisions: naming, package/API repetition, comments, errors, imports, receivers, interfaces, zero values, control flow, context, concurrency, tests, and generics.
4. Follow links from the Google documents to the exact section before asserting a rule.
5. Distinguish:
   - mechanically enforced failure;
   - meaningful clarity or maintainability defect;
   - non-blocking style preference.

Google's ordering is clarity, simplicity, concision, maintainability, then consistency. Comments usually explain rationale that code cannot express. Prefer the least mechanism and avoid unnecessary abstractions.

## Finding gate

Report a style finding only when the changed code violates an explicit adopted rule or materially obscures correct maintenance. Cite the authoritative section URL or local convention. Formatting handled automatically is check evidence, not an inline finding. Personal preferences belong in optional nits only when requested.

Return candidates using the orchestrator contract, or `No findings.`
