
<!-- nexus:start -->
## Nexus Intelligence

*Auto-updated by Nexus — do not edit this section manually.*
*Last sync: 2026-05-13*

### Portfolio
| Project | Description | Tech |
|---------|------------|------|
| jarvis-stack | — | — |
| ai-video-producer | — | — |
| personal-brand-assistant | — | — |
| project-avatar | — | — |
| ComfyUI | **ComfyUI** — the main local ComfyUI installation at E:/ComfyUI-Easy-Install/Co… | — |
| matthewkruczek-ai | **matthewkruczek.ai** — static personal brand website for Matthew Kruczek (EY M… | — |
| **claude-code-mastery** (this) | **Claude Code Mastery** — the definitive Claude Code setup and configuration sk… | — |
| Nexus | Nexus is a local-first cross-project intelligence layer for Claude Code. | — |
| _+32 inactive_ | — | — |

### Context from Nexus
#### Roadmap: Next Features
User-approved feature ideas (2026-03-24):

1. **MCP Tool Intelligence Layer** — Nexus sits on mcp-hub, learns which tools succeed/fail per project, i…
*Tags: roadmap, features, mcp-hub, planning*

#### Backlog: Show all active MCP servers in Claude Config tab
The Claude Config dashboard page only shows MCP servers from settings.json/settings.local.json, not the full set of running servers (plugins + projec…
*Tags: backlog, dashboard, mcp, claude-config*

#### Token Budget Optimization Session - 2026-03-18
## Token Budget Optimizations Applied

### 1. Portfolio Table Filter (claude-md-sync.ts)
- Before: All 35+ projects listed in every CLAUDE.md sync (~…
*Tags: token-budget, skills, portfolio, optimization*

#### Session Insights - 2026-03-17
## Session Insights - 2026-03-17

**Scope:** 20 sessions, ~1 month, 670 total messages, 33.5 avg msgs/session

### Top Projects
1. **OpenClaw** — 5 s…
*Tags: insights, sessions, analytics*

#### OpenClaw Ollama Fallback & Stop Hook JSON Validation Fix
(1) OpenClaw agent fallback chain requires tool-capable models; dolphin-llama3 doesn't support tools so was removed; llama3.1:8b being pulled as Olla…
*Tags: openclaw, ollama, hooks, bug-fix*

### Recorded Decisions
- **[security]** Sanitize and rotate credentials after eval runs that may expose secrets
  > During test case TC-003, a real GitHub PAT was exposed in skill output. Established practice to rotate credentials and document secret exposure risks in eval framework.
- **[security]** Sanitize eval test harness to prevent credential leakage from settings files
  > Eval run exposed GitHub PAT token when skill accessed actual settings.json during MCP config test
- **[security]** Include platform-aware syntax validation in evaluations — specifically test Win…
  > TC-005 and TC-003 explicitly validate Windows-compatible output; 15% of benchmark criteria allocated to platform awareness
- **[architecture]** Use MCP gateway (Bifrost at http://matthews-mac-mini.tail2800e3.ts.net:8090/mcp) to multiplex multip…
  > Simplifies MCP server configuration and tool routing; some servers expose tools directly, others require tool-info inspection
- **[architecture]** Implement memory persistence across sessions via hook system (SessionStart, Ses…
  > Preserves context across Claude sessions and compactions; daily session files and observation logs maintain continuity without manual intervention

### Active Conflicts
- [high] jarvis-stack replaces Anthropic Claude CLI with OpenRouter (Google Gemini + OpenAI GPT only), but claude-code-mastery is explicitly designed for Claude's session lifecycle hooks and tool integration—if these projects share infrastructure or call each other, the LLM swap will break session persistence and memory hooks.

> **Cross-project rule**: Before making decisions that affect shared concerns (APIs, auth, data formats, deployment) or asking the user for server/SSH/infrastructure details, run `nexus_query` to check for existing decisions, notes, and conflicts across the portfolio.
> When the user says "save to nexus" or you learn something worth preserving across sessions (project identity, key entities, architecture decisions, cross-project relationships), call `nexus_note` with `action: "set"` and a descriptive `title`.

*[Nexus: `nexus_query` to search | `nexus_note` to save | `nexus_decide` to record decisions]*
<!-- nexus:end -->
