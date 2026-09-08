# Security

## Secrets Management

- NEVER hardcode secrets, API keys, tokens, or connection strings in code, scripts, profiles, settings files, or docs. Fetch at runtime.
- **Local secret store (this machine) = Windows Credential Manager via the DevSecrets vault at `C:\Users\kruz7\.devsecrets\`** (DPAPI, per-user, not OneDrive-synced). Entries are `DevSecret:<NAME>`. Retrieve:
  - PowerShell: `Import-Module C:\Users\kruz7\.devsecrets\DevSecrets.psm1; Get-DevSecret -Name <NAME>` (list: `Get-DevSecretNames`)
  - Python: `import sys; sys.path.insert(0, r"C:\Users\kruz7\.devsecrets"); from devsecrets import get_secret` → `get_secret("<NAME>")`
  - Node: `require("C:/Users/kruz7/.devsecrets/devsecrets.js").getSecret("<NAME>")`
  - Cheat-sheet + full entry list: `C:\Users\kruz7\.devsecrets\README.md`
- Other homes: .NET projects → `dotnet user-secrets`; GitHub → `gh` auth store; Anthropic → Claude-managed (`~/.claude/.credentials.json`); Prod → Azure Key Vault.
- Frontend: NEVER put secrets in Angular/client-side code — backend proxies all external API calls.
- If a secret is exposed: rotate immediately, check Application Insights for exploitation.

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

## Supply Chain

- Run `dotnet list package --vulnerable` and `npm audit` before adding new dependencies.
- Pin major versions. Review changelogs before upgrading.

## If Security Issue Found

1. STOP current work — security takes priority over all other tasks.
2. Fix CRITICAL issues before resuming other work.
3. Rotate any exposed secrets, audit logs for exploitation.
