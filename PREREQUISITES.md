# Prerequisites — install before `install.ps1` is fully useful

`install.ps1` copies config and calls the `claude` CLI. It does not install any of the
following. Some hooks will silently no-op or error until these are present; none of it blocks
Claude Code from starting.

## Required for the CLI itself

- **Claude Code** — install and run `claude login` once, so `~/.claude.json` and
  `~/.claude/.credentials.json` exist. Do this before running `install.ps1`.
- **Developer Mode** (Settings → Privacy & Security → For developers) or an elevated shell —
  needed for `install.ps1` to create the skill symlinks listed in `links.json`. Without it, the installer falls back
  to directory junctions, which work for local reads but won't match a real symlink's behavior
  if something inspects link type.

## Runtime hosts several hooks call directly

`settings.json` invokes some of these by absolute path rather than relying on PATH — if your
install locations differ, edit the relevant hook command in `~/.claude/settings.json` after
install.

| Tool | Used by | Notes |
|---|---|---|
| **Node.js** | most hooks (`.mjs`) | `context-mode-cache-heal.mjs` currently hardcodes `C:\nvm4w\nodejs\node.exe` (nvm-for-windows) — update the path if you install Node differently |
| **Python 3.13** | `langfuse_hook.py`, `semgrep-async-scan.py` | hardcodes `AppData\Local\Programs\Python\Python313\python.exe` for the Langfuse hook; the semgrep hook uses bare `py` |
| **PowerShell 7 (`pwsh`)** | 8+ hook commands, all `scripts/*.ps1`, profile switching | |
| **Git Bash (`bash`)** | statusline (`context-governor/dispatcher.sh`), `auto-format.sh` | this package assumes Git for Windows is installed |
| **`gh` CLI** | issue/PR workflow (rules/agents.md), `git-safety.ps1` | `gh auth login` separately — its token isn't in the vault |
| **`dotnet` + `csharpier`** | `auto-format.sh` | looks for csharpier under `.dotnet\tools` |
| **`semgrep`** | 3 semgrep hook scripts, security-reviewer agent | needs the ruleset too — see below |
| **`prettier`, `jq`** | `auto-format.sh`, `config-protection.ps1` | |
| **Ollama** | `ollama_task_delegate.py` (currently disabled via `CLAUDE_DISABLED_HOOKS`) | only matters if you re-enable it |
| **`bun`** | `blender-agent-studio` MCP server | |
| **`git`** | `install.ps1` (clones the `claude-code-playground` mods marketplace) | ships with Git for Windows |

## Things this package deliberately does not carry — get them separately

| Item | Why excluded | How to get it |
|---|---|---|
| **`semgrep-rules/`** | was a full vendored clone of `semgrep/semgrep-rules` (9.6 MB, its own git history) — re-cloning is more current than a frozen copy | `git clone https://github.com/semgrep/semgrep-rules ~/.claude/hooks/semgrep-rules` |
| **`github-mcp-server.exe`** | 25 MB versioned binary (currently v1.8.0), not config | Download `github-mcp-server_Windows_x86_64.zip` from the `github/github-mcp-server` GitHub releases page, extract into `~/.claude/mcp-servers/github-mcp-server/` |
| **The Nexus project** | a full separate codebase under `OneDrive\...\MCKRUZ\Nexus`, not part of Claude Code config | Clone it to the same relative path and build it (`packages/cli`, `packages/mcp`), or accept that 3 hooks (UserPromptSubmit, SessionStart sync, SessionEnd post-session) will silently no-op |
| **`blender-agent-studio`** | upstream clone (24 MB, its own git history) used by the MCP server of the same name | `git clone https://github.com/ifBars/blender-agent-studio ~/.claude/mcp-servers/blender-agent-studio`. The registration also hardcodes `BLENDER_EXECUTABLE=F:\Blender 5.2\blender.exe` — fix it in `~/.claude.json` to match your Blender install |
| **`rea` (reverse-engineering MCP server)** | global npm package plus Ghidra and a JDK, all at machine-specific paths | `npm i -g rea-agents`, install Ghidra 12.1.4 and JDK 21, then fix the `command`, `GHIDRA_INSTALL_DIR` and `JAVA_HOME` values in `~/.claude.json` (registered as `C:\nvm4w\nodejs\...`, `C:\Tools\ghidra_12.1.4_PUBLIC`, `C:\Tools\jdk-21.0.12.1+1`) |
| **The jarvis-os project** | a separate codebase under `OneDrive\...\MCKRUZ\jarvis-os` | Clone it to the same relative path, or accept that the HUD hooks (`jarvis-hud-forward.mjs`) and the statusline's rate-limit tap stay silent. Both fail quietly, so nothing errors |
| **`donsetch.exe`, `comfy-mcp.exe`** | user-installed tools outside `~/.claude`, referenced by 2 MCP servers | reinstall those tools if you want those MCP servers to work; otherwise remove the entries from `~/.claude.json` |
| **`wt-local` plugin marketplace** | sources from a Windows Terminal Canary preview app's local staging path — machine-specific by nature | `install.ps1` skips it automatically; reinstall manually only if that terminal app is on this machine |

## Needs a sign-in on first use

- **`readwise` MCP server** — remote server using OAuth. The first call opens a browser sign-in; nothing to pre-configure.

## Already broken on the source machine — not a migration regression

Two things in this package reference a project folder that no longer exists even on the source
machine. They're included because scope was "everything reproducible," but don't expect them to
work without further changes:

- `commands/refresh.md` (`/refresh` slash command) → points at `MCKRUZ\claude-remote`
- `scripts/sync-skill-{to,from}-repo.ps1` → point at `MCKRUZ\ComfyUI Expert`
