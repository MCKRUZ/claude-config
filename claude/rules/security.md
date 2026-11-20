---
paths:
  - "**/*.{cs,csproj,ts,tsx,js,mjs,cjs,py,html}"
  - "**/{package.json,pyproject.toml,Dockerfile}"
  - "**/requirements*.txt"
  - "**/appsettings*.json"
  - "**/*.{bicep,tf}"
---

# Security (application code)

Loads when code, dependency manifests or infrastructure files are touched. Secrets, supply-chain
and incident rules are always loaded from `security-baseline.md`.

## Input Validation & Injection

- All user input validated at system boundaries (FluentValidation / Angular reactive forms).
- SQL: EF Core only (auto-parameterized). Raw SQL: `FromSqlInterpolated` only — never string concatenation.
- XSS: Angular auto-escapes by default. Use `DomSanitizer` only when unavoidable, with a comment explaining why.
- CSRF protection enabled on all state-changing endpoints.

## Authentication & Authorization

- Auth required on all endpoints. Rate limiting on public endpoints.
- JWT: ValidateLifetime=true, ClockSkew=Zero, validate issuer + audience + signing key.
- CORS: explicit allowlist only (`CorsAllowedOrigins`), never wildcard in production.

## HTTP Security Headers

- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Content-Security-Policy: restrictive default
- Strict-Transport-Security: max-age=31536000; includeSubDomains
- Error responses: never leak stack traces, internal paths, or sensitive data.

## AI/LLM Security

- Validate and sanitize all LLM inputs and outputs — treat model output as untrusted.
- Content safety middleware on all agent endpoints.
- Tool permissions enforced via pipeline behavior — tools only accessible to authorized agents.
- Prompt injection defense: never embed raw user input directly into system prompts.
