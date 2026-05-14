# PowerPoint Creator

A web application that lets users chat with an AI agent to create McKinsey-quality PowerPoint-style presentations. Presentations are rendered as HTML slides and exported to PDF (not native PPTX). Uses the Microsoft Agent Framework with Azure OpenAI models.

## Tech Stack

- **Backend**: .NET 10, PostgreSQL, MediatR, FluentValidation, Serilog
- **AI**: Azure OpenAI (via Azure.AI.OpenAI SDK), Microsoft Agent Framework
- **Document Processing**: DocumentFormat.OpenXml for PPTX template parsing
- **SharePoint**: Microsoft.Graph + MSAL (OBO flow)
- **PDF Export**: Microsoft.Playwright
- **Frontend**: Angular 19 (future phase)

## Architecture

Clean Architecture with strict dependency flow: Domain <- Application <- Infrastructure/Api.

```
src/
  PowerPointCreator.Api/            -> Minimal APIs, SignalR hub
  PowerPointCreator.Application/    -> MediatR handlers, FluentValidation, interfaces
  PowerPointCreator.Domain/         -> Entities, value objects, enums (no dependencies)
  PowerPointCreator.Infrastructure/ -> Azure OpenAI agent, SharePoint, OpenXML, Playwright
  PowerPointCreator.Web/            -> Angular 19 (future)
tests/
  PowerPointCreator.Application.Tests/
  PowerPointCreator.Infrastructure.Tests/
  PowerPointCreator.Api.Tests/
```

## Commands

```bash
# Build
dotnet build

# Test all
dotnet test

# Test single project
dotnet test tests/PowerPointCreator.Application.Tests

# Run API (default: https://localhost:5001)
dotnet run --project src/PowerPointCreator.Api

# Docker (PostgreSQL)
docker compose up -d

# EF Migrations
dotnet ef migrations add <Name> --project src/PowerPointCreator.Infrastructure --startup-project src/PowerPointCreator.Api

# Apply migrations
dotnet ef database update --project src/PowerPointCreator.Infrastructure --startup-project src/PowerPointCreator.Api
```

## Code Style

### Immutability (Critical)
- Use records for DTOs and value objects.
- Use `with` expressions for modifications, never mutate in place.
- Prefer `ImmutableList<T>`, `IReadOnlyList<T>`, and `IReadOnlyDictionary<TK, TV>`.
- Spread/copy patterns for all state transitions.

### Naming Conventions (C#)
- **PascalCase**: Classes, methods, properties, public members.
- **_camelCase**: Private fields (with underscore prefix).
- **camelCase**: Local variables, parameters.

### File Organization
- Many small files over few large files.
- Target 200-400 lines per file, 800 absolute maximum.
- Organize by feature/domain, not by type.
- High cohesion, low coupling.

### Error Handling
- Use `Result<T>` pattern for business logic outcomes.
- Structured logging via Serilog (never `Console.WriteLine`).
- Global exception handler catches unhandled exceptions.
- Never expose raw AI errors or stack traces to the client.

### Functions
- Keep functions under 50 lines.
- No deep nesting beyond 4 levels.
- No hardcoded values -- use configuration or constants.

## Security

- **Secrets**: User Secrets for development, Azure Key Vault for production. Never hardcode secrets.
- **Validation**: FluentValidation on all DTOs at the Application layer.
- **Database**: EF Core parameterized queries only. Raw SQL via `FromSqlInterpolated` only.
- **Endpoints**: Rate limit all public endpoints. Auth required on all non-public endpoints.
- **Headers**: X-Frame-Options:DENY, X-Content-Type-Options:nosniff, CSP, HSTS 365d.
- **JWT**: ValidateLifetime=true, ClockSkew=Zero, validate issuer+audience+signing key.
- **Frontend**: Never put secrets in Angular. Backend proxies all external API calls.

## Testing

- **Minimum coverage**: 80%.
- **Framework**: xUnit with AAA pattern, Moq for mocks.
- **Integration**: `WebApplicationFactory<Program>` with in-memory database.
- **Pattern**: Unit + Integration + E2E for critical flows.

## Task Approach

- Use `/deep-plan` for changes touching 3 or more files.
- Agent logic must be modular -- each capability is a separate tool class.
- All AI calls go through `PresentationAgentService` in Infrastructure. Never call Azure OpenAI from endpoints directly.
- SignalR pushes slide updates to the client in real time.
- Presentation rendering is pure HTML/CSS -- no external dependencies.
