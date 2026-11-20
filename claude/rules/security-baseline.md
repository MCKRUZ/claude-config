# Security Baseline

Always loaded. Application-code rules (validation, auth, headers, LLM endpoints) live in
`security.md`, which loads when code files are touched.

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

## Supply Chain

- Run `dotnet list package --vulnerable` and `npm audit` before adding new dependencies.
- Pin major versions. Review changelogs before upgrading.

## If Security Issue Found

1. STOP current work — security takes priority over all other tasks.
2. Fix CRITICAL issues before resuming other work.
3. Rotate any exposed secrets, audit logs for exploitation.
