# Secrets checklist — names only, no values

Nothing in this package contains a secret value. Your vault (`DevSecrets`, backed by Windows
Credential Manager) is DPAPI-encrypted per user *and* machine — copying the vault files does
nothing useful on a different machine. Re-enter each value directly on the new machine:

```powershell
Import-Module $env:USERPROFILE\.devsecrets\DevSecrets.psm1   # installed by install.ps1
Set-DevSecret -Name <NAME>    # prompts securely, no echo, not saved to shell history
```

## Needed for Claude Code itself

These 4 are read by MCP servers or hooks that `install.ps1` restores. Nothing else in
`~/.claude` will work until these are set.

| Name | Used by |
|---|---|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | `github` MCP server |
| `YOUTUBE_API_KEY` | `youtube` MCP server |
| `APIFY_TOKEN` | `reddit-apify`, `tiktok-apify`, `instagram-apify` MCP servers |
| `LANGFUSE_SECRET_KEY` | Langfuse tracing hook (only if `TRACE_TO_LANGFUSE=true`, which it is in `settings.json`) |

## Belong to other projects — only if you use them on the new machine

Everything below was in the vault for other tools (Nexus, ComfyUI, social/video pipelines,
infra). Claude Code itself doesn't need them. Set only what the corresponding project needs.

```
AIVP_DASHBOARD_PASSWORD         ANTHROPIC_API_KEY             BRIDGE_TOKEN
BUFFER_API_KEY                  CIVITAI_API_KEY               CLOUDFLARE_API_TOKEN
CUEPOINT_VM_PASSWORD            DISCORD_BOT_TOKEN             DISCORD_BOT_TOKEN_JARVIS
EXTERNAL_API_KEY                EXTERNAL_API_KEY_LOCAL_OLD    FAL_KEY
GEMINI_API_KEY                  GEORGIA_LMS_CONNECTION_STRING GOG_KEYRING_PASSWORD
HEYGEN_API_KEY                  HUGGINGFACE_TOKEN             JARVIS_PANELS_TOKEN
LINKEDIN_CLIENT_ID              LINKEDIN_CLIENT_SECRET        MINI_SUDO
NEXUS_LANGFUSE_BASE_URL         NEXUS_LANGFUSE_PUBLIC_KEY     NEXUS_LANGFUSE_SECRET_KEY
NTFY_PASSWORD                   NTFY_TOKEN                    OPENAI_API_KEY
OPENCLAW_GATEWAY_TOKEN          OPENROUTER_API_KEY            PBA_ENCRYPTION_KEY
PEXELS_API_KEY                  PIXABAY_API_KEY               PORTAINER_API_TOKEN
R2_ACCESS_KEY_ID                R2_SECRET_ACCESS_KEY          READWISE_TOKEN
REDDIT_CLIENT_SECRET            SCRAPECREATORS_API_KEY        SEMGREP_APP_TOKEN
SERPAPI_API_KEY                 SQL_PASSWORD                  TIKTOK_ACCESS_TOKEN
TIKTOK_CLIENT_KEY               TIKTOK_CLIENT_SECRET          TIKTOK_REFRESH_TOKEN
TT_PSEUDONYMIZATION_KEY         TT_RUNNER_SMTP_PASSWORD       YOUTUBE_ANALYTICS_CLIENT_ID
YOUTUBE_ANALYTICS_CLIENT_SECRET YOUTUBE_CLIENT_SECRET         YOUTUBE_OAUTH_TOKEN
```

## Explicitly NOT in the vault (by design — see `devsecrets/README.md`)

- **GitHub PAT** for `gh` CLI itself — use `gh auth login`, not the vault.
- **Anthropic/Claude auth** — run `claude login` on the new machine. Don't copy
  `.credentials.json` between machines; it's a live session token.
- **`LANGFUSE_PUBLIC_KEY`** — not a secret, already sits in `claude/settings.json` as
  `pk-lf-local-claude-code`.
