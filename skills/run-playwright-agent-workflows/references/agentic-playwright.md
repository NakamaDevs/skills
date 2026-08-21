# Agentic Playwright reference

## Current Microsoft workflow

- The [NakamaDevs Playwright CLI fork](https://github.com/NakamaDevs/playwright-cli) recommends CLI plus installed skills for coding agents because it avoids large MCP tool schemas and verbose page trees. MCP remains useful for persistent, stateful exploratory loops.
- The official [Playwright test-agents guide](https://playwright.dev/docs/test-agents) defines a planner → generator → healer sequence and says generated agent definitions must be refreshed when Playwright changes.
- Recent CLI releases added file-backed `run-code`, skill discovery through `--help`, smaller snapshots, snapshot `find`, named/persistent sessions, a monitoring dashboard, mobile emulation, non-2xx navigation reporting, high-resolution screenshots, trace/video support, and secret filtering in console artifacts.
- The repository snapshot researched on 2026-08-14 pins `@playwright/cli` 0.1.18. Treat that as a reviewed pin, not a permanent latest version: inspect the official [CLI releases](https://github.com/microsoft/playwright-cli/releases) and the pinned command's `--help` before upgrading this reference or agent workflows.

## Safety and durability

- Keep sessions isolated by default. Never attach to a personal profile or transmit secrets without explicit authorization.
- Configure a dedicated artifact directory and redact secrets. Traces, videos, screenshots, storage state, and page snapshots can contain private data.
- Use CLI exploration to discover flows and debug failures. Commit generated tests only after reviewing behavior, locators, fixtures, and assertions.
- Do not let a healer weaken an assertion or silently accept an error page.
- Pin versions in repository tooling; do not use an unbounded `latest` in a repeatable gate.

## Page-object adoption

During planning, identify stable pages and reusable components. During generation, reuse their page objects instead of emitting selectors into every spec. During healing, repair the centralized locator or action only when the product contract is unchanged; keep journey-specific assertions in the tests so a healer cannot conceal a behavior regression behind a page-object rewrite.
