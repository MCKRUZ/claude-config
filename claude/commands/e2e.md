---
description: Generate and run end-to-end tests with Playwright. Creates test journeys, runs tests, captures screenshots/videos/traces on failure.
---

# /e2e — Playwright End-to-End Tests

Generate, maintain, and run end-to-end tests for the current repo using Playwright.
`$ARGUMENTS` names the user journey to cover (e.g. `/e2e test the login flow`). With no
arguments, propose the highest-value journeys first and confirm before generating.

## Process

1. **Orient.** Find the existing Playwright setup: `playwright.config.*`, the test
   directory it points at, and any existing page objects or fixtures. Match the repo's
   conventions — file layout, naming, base URL, auth helpers. If Playwright isn't set up,
   say so and offer `npm init playwright@latest` before generating anything.
2. **Identify the journey.** Turn the requested flow into concrete steps with observable
   outcomes (navigation happened, element visible, API responded). One spec file per
   journey.
3. **Generate the test.** Follow the repo's existing style; where the repo has none:
   - `data-testid` selectors — never CSS classes or brittle text matches
   - Page Object Model when the repo already uses it; plain tests otherwise
   - Wait on responses/elements (`waitForResponse`, `expect(...).toBeVisible()`),
     never arbitrary timeouts
   - Cover the happy path plus the journey's meaningful failure state (empty results,
     validation error) — edge cases belong in unit tests
4. **Run it.** `npx playwright test <spec>` — headed/debug only if asked. The app must be
   running or started via the config's `webServer`; check before blaming the test.
5. **Report.** Pass/fail per test, duration, and where the artifacts landed (HTML report,
   screenshots/videos/traces on failure). On failure, read the trace/screenshot before
   proposing a fix — diagnose from evidence, not the test title.

## Flaky tests

A test that fails intermittently gets diagnosed, not retried into submission: identify the
race (missing wait, animation, network timing), fix the wait condition, and only quarantine
with `test.fixme()` + a comment if the fix needs product changes.

## Guardrails

- Never run E2E against production. Tests that touch money, real user data, or
  irreversible actions run against local/test environments only.
- Don't test implementation details — journeys the user experiences, end to end.
- Keep E2E suites small and critical; breadth belongs to unit/integration tests
  (see `rules/testing.md`).

## Quick reference

```bash
npx playwright test                      # all E2E tests
npx playwright test path/to/spec.ts      # one spec
npx playwright test --headed             # watch the browser
npx playwright test --debug              # step through
npx playwright show-report               # open HTML report
npx playwright codegen <url>             # record interactions as code
```
