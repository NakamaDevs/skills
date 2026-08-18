---
name: build-playwright-go-e2e
description: Build, update, run, or review durable browser acceptance tests in Go with github.com/mxschmitt/playwright-go. Use for Go web applications, cross-browser journeys, browser fixtures, selectors, traces, screenshots, CI E2E tasks, and Playwright driver/version setup.
---

# Build Playwright Go E2E

Use the maintained community Go client at `github.com/mxschmitt/playwright-go`. Match its module version to the installed Playwright driver; reinstall the driver after every minor client upgrade.

## Build a durable journey

1. Define one critical user outcome and its acceptance assertions.
2. Start the real application on loopback with isolated temporary data and parse its reported dynamic URL.
3. Launch Playwright, create a fresh browser context per test, and close page, context, browser, Playwright, and process deterministically.
4. Prefer role, label, text, and explicit test-id locators over CSS structure or generated classes.
5. Adopt Page Object Model classes or structs for recurring pages and meaningful page components. Wrap `playwright.Page`, centralize locators and user actions, and expose an application-language API to tests.
6. Keep journey-specific expectations in tests. Put only stable page invariants or reusable readiness checks in page objects; do not create assertion-heavy god objects.
7. Use Playwright auto-waiting and assertions; never add fixed sleeps.
8. Assert behavior at normal and constrained viewports when responsive layout is in scope.
9. Save trace, screenshot, console, and service logs on failure.
10. Keep only a few critical journeys; cover permutations below the E2E layer.

Read [references/playwright-go.md](references/playwright-go.md) before installing or upgrading the driver.

## Validation

Run the repository's pinned browser-install task, focused E2E task, and full quality gate. Repeat the E2E suite to detect state leakage when risk warrants it.
