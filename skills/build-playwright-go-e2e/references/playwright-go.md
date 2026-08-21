# Playwright Go reference

## Authority and versioning

- BrowserStack's [Playwright for Go guide](https://www.browserstack.com/guide/playwright-go) recommends isolated browser contexts, handling dynamic content through Playwright, controlled parallelism, and traces/debugging. Its generic `npx playwright install` advice is not authoritative for the Go driver's version.
- The primary [playwright-go repository](https://github.com/mxschmitt/playwright-go) is a community client, not an official Microsoft Go binding. Its module moved from `github.com/playwright-community/playwright-go` to `github.com/mxschmitt/playwright-go` in v0.6100.0.
- This repository pins `github.com/mxschmitt/playwright-go` v0.6100.0, whose release bundles Playwright driver 1.61.1. Recheck the primary release notes before changing either side of that pair.
- Install the exact matching driver and browsers with `go run github.com/mxschmitt/playwright-go/cmd/playwright@<module-version> install <browser>`. Each minor client upgrade requires a matching driver reinstall.

## Reliability rules

- Use one isolated context per test.
- Let Playwright wait on actionable locators; use bounded readiness checks for the service process.
- Parse a server-selected loopback port instead of reserving a fixed port.
- Avoid shared persistent profiles in regression tests.
- Keep this repository local-only. Do not add BrowserStack, another cloud grid, paid testing services, credentials, or remote browser data transfer. Treat BrowserStack's article only as secondary usage guidance.

## Page Object Model in Go

Playwright's official [Page Object Model guide](https://playwright.dev/java/docs/pom) defines a page object as a wrapper over a Playwright `Page` that represents a page or meaningful part of the application. It centralizes selectors and exposes a higher-level application API, reducing duplication and limiting selector maintenance to one place.

Use a Go struct per cohesive page or reusable component:

```go
type SignInPage struct {
    page playwright.Page
    Email playwright.Locator
    Submit playwright.Locator
}

func NewSignInPage(page playwright.Page) *SignInPage {
    return &SignInPage{
        page: page,
        Email: page.GetByLabel("Email"),
        Submit: page.GetByRole("button", playwright.PageGetByRoleOptions{Name: "Sign in"}),
    }
}

func (page *SignInPage) SignIn(email string) error {
    if err := page.Email.Fill(email); err != nil {
        return err
    }
    return page.Submit.Click()
}
```

Keep the user outcome visible in the test: call `SignIn`, then assert the expected authenticated result there. Split page objects when they become navigation-wide dumping grounds. Do not hide arbitrary waits, broad exception handling, test data generation, or unrelated assertions inside them.
