# MCP Servers

All MCP servers run **locally on this machine** as of 2026-08-06. The Bifrost gateway on the Mac Mini was retired — there is no proxy, no Code Mode, and no `listToolFiles` / `readToolFile` / `getToolDocs` / `executeToolCode` dance. Every server's tools are addressed directly.

Registered in `~/.claude.json` (user scope) via `claude mcp add -s user`. Tool schemas load on demand, so having many servers registered costs almost nothing until one is used.

## Credentials

Servers needing a key are launched through `C:\Users\kruz7\.claude\mcp-servers\launch.js`, which reads the value from the DevSecrets vault (Windows Credential Manager) at start-up and passes it to the child process. **No token is ever written into `.claude.json`.** To add another keyed server:

```
claude mcp add -s user <name> -- node C:\Users\kruz7\.claude\mcp-servers\launch.js --secret <VAULT_NAME> -- <command> [args]
```

## Tool selection priority

1. **Built-in tools** (WebSearch, WebFetch, Bash, Read, Grep, Edit) — zero friction, use when they cleanly satisfy the task.
2. **`gh` CLI via Bash** for single-shot GitHub reads (view PR, list issues).
3. **An MCP server below**, when its specialist capability beats what a built-in can do.

Don't reach for a server just because it exists.

## The servers

### context7 — version-specific library API reference

Up-to-date API signatures and code examples for third-party libraries; authoritative for exact method/config/flag details training data may have wrong. Reach when verifying a specific method signature, config option, or version-specific behaviour in React, Angular, xUnit, FluentValidation, MediatR, or similar. Not for general concept explanations.
Flow: `resolve-library-id` → `query-docs`.

### microsoft-learn — authoritative Microsoft docs

Official Microsoft/Azure/.NET documentation, more reliable and more current than general web search for Microsoft APIs. Reach when working on .NET, ASP.NET Core, EF Core, Azure SDK, Bicep, ARM schema, or M365, or verifying an SDK method, Azure CLI flag, or Bicep property.

### sequential-thinking — structured multi-step reasoning

Forces explicit branching, revision, and hypothesis-testing. Overhead isn't worth it for routine work. Reach when weighing architectural trade-offs, debugging an issue whose root cause is unclear, or planning across 3+ files.

### youtube — programmatic video data

Transcripts, statistics, comments, and channel data. Reach when the user references a specific video or channel, or the best technical content on a topic lives in video form (conference talks, deep-dive walkthroughs).

### reddit-apify — community sentiment

Real user opinions with thread context, via Apify (needs no Reddit API credentials and is not subject to Reddit's bot block). Single tool: `reddit_search`. Reach for "what do people actually think of X" or "is there existing discussion of Y".

### searxng — metasearch

Aggregated web search across engines. Runs as a container on the Mac Mini (`searxng-mcp`, port 3080) and is reached over Tailscale — it is **not** local. Built-in WebSearch is usually the lighter choice; reach for this when you want engine-diverse results.

### github — orchestrated GitHub workflows

GitHub's **official** MCP server (44 tools), run as a local binary at `C:\Users\kruz7\.claude\mcp-servers\github-mcp-server\`. Structured, multi-step GitHub operations. For single reads (view PR, list issues, check status), prefer the `gh` CLI — it's faster and already in the toolbelt.

Currently v1.8.0. It does not self-update; to upgrade, download the newest `github-mcp-server_Windows_x86_64.zip` from the `github/github-mcp-server` releases page and replace the `.exe` in place — no config change needed.

> Replaced `@modelcontextprotocol/server-github` on 2026-08-06. That package is formally deprecated ("no longer supported") and its last release was April 2025.

### playwright / chrome-devtools — browser automation

Both are registered, but **`claude-in-chrome` is usually the better choice**: it drives the real Chrome session rather than a fresh headless browser. Reach for playwright when you specifically need an isolated, scripted browser independent of the user's session.

### firecrawl — JS-rendered pages, structured extraction, site crawling

Points at the self-hosted Firecrawl engine on the NAS (`http://bablyon:3002`).

Verified working 2026-08-06: 12/12 scrapes succeeded, averaging 0.8s. The 19% success rate seen historically was Bifrost's own request timeout, not the engine — removing the gateway fixed it.

> **Caveat:** the NAS is resource-constrained (load average ~7 on 4 cores, ~2 GB swap in use) and Firecrawl sheds load when the box is busy, logging `Can't accept connection due to RAM/CPU load`. Scrapes can fail in bursts under load and succeed on retry. If failures become frequent rather than occasional, the fix is to give the NAS headroom or raise Firecrawl's `MAX_CPU`/`MAX_RAM` thresholds — not to blame the MCP server.

## Not migrated

**reddit-mcp-server** (the plain Reddit API server, 23 tools) was dropped. Its Reddit app credentials are dead — both the pair on the Mac Mini and the local vault's `REDDIT_CLIENT_SECRET` fail OAuth with 401. It last succeeded 2026-06-28. `reddit-apify` covers the same need and works. To revive it, register a new app at https://www.reddit.com/prefs/apps, store the ID and secret in the vault, and add it through `launch.js`.

## Rolling back to Bifrost

The gateway container still exists on the Mac Mini, stopped, with its config database and env file intact:

```
ssh matthewkruczek@matthews-mac-mini.tail2800e3.ts.net '/usr/local/bin/docker start bifrost'
claude mcp add -s user -t http bifrost http://matthews-mac-mini.tail2800e3.ts.net:8090/mcp
```
