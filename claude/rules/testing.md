---
paths:
  - "**/*.{cs,csproj,razor,ts,tsx,js,jsx,mjs,cjs,py}"
---

# Testing

Loads when code files are touched. The bug-fix workflow (reproduce with a failing test first)
is always loaded from CLAUDE.md, because a bug report arrives before any file is opened.

## Test Philosophy

Tests must encode WHY behavior matters, not just WHAT it does. A test that can't fail when the underlying business logic changes is wrong.

## Coverage: 80% minimum

Unit + Integration + E2E for critical flows.

## Test Naming

- C#: `MethodName_Scenario_ExpectedResult` (e.g., `Handle_InvalidRequest_ReturnsValidationFailure`)
- TypeScript/Angular: descriptive `it('should ...')` strings
- Python: `test_scenario_expected_result`

## Mocking Discipline

- Prefer real implementations over mocks. Use `WebApplicationFactory<Program>` + in-memory DB for integration tests.
- Only mock external services (HTTP clients, third-party APIs) and time (`TimeProvider`).
- Never mock the thing you're testing. Never mock value objects or DTOs.

## Patterns

- C#: xUnit, Arrange-Act-Assert, Moq (sparingly), `WebApplicationFactory<Program>` + in-memory DB for pipeline tests
- Angular: Jasmine/Karma, `HttpTestingController`, `afterEach(() => httpMock.verify())`
- Python: pytest, fixtures over setup methods, parametrize for variant cases
- E2E: Playwright with `data-testid` selectors

## Commands

- C#: `dotnet test`, `dotnet test --collect:"XPlat Code Coverage"`
- Angular: `ng test --code-coverage`, `ng test --watch=false --browsers=ChromeHeadless`
- Python: `pytest`, `pytest --cov`
- E2E: `npx playwright test`
