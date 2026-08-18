---
name: run-playwright-agent-workflows
description: Explore, plan, generate, heal, or debug browser workflows with Microsoft Playwright CLI, Playwright agents, or Playwright MCP. Use for agentic SDLC browser exploration, CLI sessions, snapshots, test generation, selector repair, MCP tradeoffs, and converting exploratory actions into durable committed tests.
---

# Run Playwright agent workflows

Use agent browser tooling for discovery and repair. Convert accepted behavior into deterministic repository tests; never treat an ephemeral agent session as regression coverage.

## Select the interface

- Prefer Playwright CLI plus its skill for coding agents: concise commands and file-backed snapshots use less context.
- Prefer MCP for persistent exploratory loops that need rich live page introspection or recovery.
- Prefer committed Playwright tests for CI, repeatability, review, and release gates.

## Workflow

1. Pin the Playwright CLI version and inspect `playwright-cli --help` because commands evolve quickly.
2. Start an isolated named session; do not reuse a personal authenticated profile.
3. Explore the target and save small snapshots with depth limits or `find` rather than flooding context.
4. Produce a human-readable test plan.
5. Generate readable Playwright tests using repository fixtures, semantic locators, and existing Page Object Models. Create or extend a focused page object when selectors or user actions recur.
6. Execute and heal only when the repaired assertion still matches the product requirement.
7. Review the diff and artifacts; reject duplicated inline selectors, oversized page objects, or assertions that merely make the test green.
8. Close sessions and keep only intentional traces/screenshots.

Read [references/agentic-playwright.md](references/agentic-playwright.md) for current CLI capabilities, the planner/generator/healer loop, and security boundaries.
