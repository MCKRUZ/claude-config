# Claude Code config — portable package

A packaged copy of the Claude Code configuration from `C:\Users\kruz7`, built for installing on
a different Windows machine. Contains zero secrets and zero session/telemetry data — only the
config you'd actually recognize as "your settings": `CLAUDE.md`, rules, custom agents, slash
commands, hooks, skills, profiles, and the MCP server list.

Started ~1.7 GB on the source machine (mostly session history, plugin caches, and logs). This
package is **~45 MB**. Last refreshed from the live machine on 2026-10-26.

## Install order

1. Install Claude Code on the new machine and run `claude login` (creates `~/.claude.json` and
   the auth token file this package deliberately does not carry).
2. Read `PREREQUISITES.md` — install what you don't already have (Node, Python, PowerShell 7,
   Git Bash, `gh`, `dotnet`+csharpier, semgrep, etc.). Nothing here blocks step 3, but hooks that
   depend on missing tools will error until you do this.
3. Run `.\install.ps1` from this folder. It's non-destructive — anything it would overwrite gets
   renamed aside with a `.pre-migration-<timestamp>` suffix first, nothing is deleted.
   - `-WhatIf` to preview without writing anything
   - `-SkipPlugins` / `-SkipMcp` to skip those phases (e.g. to retry just the file copy)
4. Work through `SECRETS-CHECKLIST.md` — re-enter the 4 secrets Claude Code itself needs
   (`Set-DevSecret -Name <NAME>`, values only, never files).
5. Run `.\verify.ps1` — reports what installed cleanly vs what still needs attention.

## What's deliberately NOT here

| Excluded | Why |
|---|---|
| Session history, `sessions/`, `projects/`, caches, logs, telemetry, `context-mode/` runtime data (384 MB), `context-governor/data/` (149 MB) | machine/session state, regenerates itself |
| `.credentials.json` | live Claude auth token — run `claude login` instead |
| All 44 vault secrets | DPAPI-encrypted per user+machine, the files are useless elsewhere — see `SECRETS-CHECKLIST.md` |
| `plugins/cache/` (1.1 GB), `plugins/marketplaces/` (454 MB) | downloaded plugin content — `install.ps1` replays the marketplace + install commands instead of copying the cache |
| `semgrep-rules/` (vendored upstream clone), `github-mcp-server.exe` (25 MB binary), `mcp-servers/blender-agent-studio/` (upstream clone) | third-party content better fetched fresh — see `PREREQUISITES.md` |
| `mods/claude-code-playground/` | upstream clone that backs a plugin marketplace — `install.ps1` re-clones it |
| `skills/synced/` | claude.ai-managed skills, re-synced by the app on sign-in |
| Nested `.git`, `node_modules`, `__pycache__` folders inside skill folders and the archived `claude-code-mastery` package | clone history and build output, not settings — stripped so this package is one clean repo, not a nest of embedded repos |
| `*.bak-*`, `*.before-*`, `*.log` files | backups and logs, not live config |

Full reasoning for every inclusion/exclusion decision: see the build plan this package was made
from, or ask whoever ran the packaging session.

## Known gaps after install

- **Nexus project hooks** (3 of them) will no-op unless you separately clone+build the Nexus
  project at the same relative OneDrive path. Not part of this package — it's a full codebase,
  not a Claude Code setting.
- **jarvis-os hooks** (the HUD forwarder and the statusline's rate-limit tap) stay silent unless
  the jarvis-os project is cloned at the same relative OneDrive path. Same reasoning as Nexus.
  `settings.json` also exports Claude Code telemetry to `127.0.0.1:47821`, the same HUD; with
  the HUD absent, those exports just fail quietly.
- **`skills-archive/claude-code-mastery`** is a frozen copy. On the source machine it was a link
  to a `claude-code-mastery` repo that no longer exists, so this copy is the only one left.
- **`/refresh` command** and the **ComfyUI skill-sync scripts** already point at a project folder
  that doesn't exist on the source machine either — not something this migration broke.
- **`wt-local` plugin marketplace** is skipped automatically (sources from a Windows Terminal
  Canary local path specific to the old machine).

## Folder contents

```
claude/           -> installs to ~/.claude
agents-skills/    -> installs to ~/.agents/skills   (linked into ~/.claude/skills and skills-archive)
devsecrets/       -> installs to ~/.devsecrets       (vault tooling only, no secret values)
links.json        -> which ~/.claude skill folders are links into ~/.agents/skills
mcpServers.json   -> the user-scope MCP server registrations, replayed via `claude mcp add-json`
install.ps1       -> the installer
verify.ps1        -> post-install health check
SECRETS-CHECKLIST.md, PREREQUISITES.md -> exactly what they say
```
