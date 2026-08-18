---
name: code-review-documentation
description: Review changed code and prose for documentation drift across user behavior, configuration, CLI/API contracts, architecture, operations, examples, Go doc comments, and agent instructions. Use when a change affects what users, operators, contributors, or future maintainers must know.
---

# Review Documentation

Documentation is part of the contract. Require updates when readers would otherwise act on stale or incomplete information; do not require prose for self-explanatory internal code.

## Identify affected readers and surfaces

Check applicable layers:

- user setup, workflows, configuration, and troubleshooting
- CLI help, API/schema reference, examples, and error behavior
- architecture, data ownership, privacy, lifecycle, and decisions
- contributor commands, generated-file workflow, and CI gates
- release/compatibility notes for externally visible changes
- Go package and exported-symbol documentation
- `AGENTS.md` and project skills when the agent workflow changes

## Verify accuracy

1. Trace every changed public behavior or contract to its canonical documentation.
2. Run or statically verify commands and examples when practical.
3. Preserve exact field names, flags, paths, defaults, versions, and modality such as must/should/may.
4. Prefer rationale and constraints over paraphrasing code.
5. Check links between schema, defaults, editor fields, runtime behavior, tests, and configuration docs.
6. Request an architecture decision record only for a significant, durable, and costly-to-reverse choice; match any existing ADR convention.

For Mensetsukan, keep `README.md`, `docs/configuration.md`, `docs/architecture.md`, `docs/agent-setup.md`, CLI help, `interview.schema.json`, and `default.config.json` consistent with their respective contracts. Do not place organization-specific interview content or private data in tracked examples.

## Finding gate

Report a finding when changed behavior makes existing documentation false, omits a required user/operator step, or leaves a public contract undiscoverable. Point to the changed code line that creates the documentation obligation when no documentation line changed. Do not flag grammar or tone unless it changes meaning or blocks comprehension.

Return candidates using the orchestrator contract, or `No findings.`
