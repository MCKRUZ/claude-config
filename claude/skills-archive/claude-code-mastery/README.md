# Claude Code Mastery

The definitive Claude Code setup, configuration, and mastery package. Battle-tested rules, agents, hooks, and 17 curated skills — one install for a complete development environment.

## What This Package Does

Helps you set up, optimize, and master Claude Code across seven pillars:

1. **CLAUDE.md Engineering** — hierarchy, golden rules, templates
2. **Context Management** — token budgeting, compaction, context-mode plugin
3. **MCP Server Stack** — gateway architecture, tiered recommendations
4. **Settings/Permissions/Hooks** — production-ready templates, lifecycle hooks
5. **Agents & Subagents** — orchestration, wave execution, agent teams
6. **Skills & Plugins** — ecosystem, 17 curated skills, plugin stack
7. **CI/CD & Automation** — headless mode, GitHub Actions, worktrees

## Installation

### APM (recommended)

```bash
# Install APM first (if you haven't)
# Windows: irm https://aka.ms/apm-windows | iex
# macOS/Linux: curl -sSL https://aka.ms/apm-unix | sh

# Install the full package (skill + 17 curated skills + rules + agents + hooks)
apm install MCKRUZ/claude-code-mastery
```

### Git Clone (skill only)

```bash
git clone https://github.com/MCKRUZ/claude-code-mastery ~/.claude/skills/claude-code-mastery
```

### npx skills

```bash
npx skills add MCKRUZ/claude-code-mastery
```

## What's Included

### Skills (via APM dependencies)

| Skill | Source |
|-------|--------|
| claude-code-mastery | This package (the core skill) |
| dashboard-creator | mhattingpete/claude-skills-marketplace |
| demo-video | MCKRUZ/demo-video-skill |
| docx | anthropics/skills |
| excalidraw-diagram-generator | coleam00/excalidraw-diagram-skill |
| find-skills | anthropics/skills |
| functional-design | MCKRUZ/functional-design |
| humanizer | blader/humanizer |
| llm-cost-optimizer | MCKRUZ/llm-cost-optimizer-skill |
| pdf | anthropics/skills |
| project-memory | SpillwaveSolutions/project-memory |
| security-review | MCKRUZ/security-review-skill |
| shannon | KeygraphHQ/shannon |
| skeptic | MCKRUZ/skeptic-skill |
| slides | MCKRUZ/slides-skill |
| tdd-workflow | MCKRUZ/tdd-workflow-skill |
| visual-explainer | nicobailon/visual-explainer |

### Instructions (deployed to `.claude/rules/` or `.github/instructions/`)

| File | What It Covers |
|------|---------------|
| `coding-style` | Immutability, naming, file organization, validation |
| `security` | Pre-commit checklist, JWT, headers, secrets |
| `testing` | 80% coverage, TDD, bug-fix-first workflow |
| `agents` | When to spawn agents, commit format, PR workflow |
| `performance` | Context window, research limits, build troubleshooting |
| `patterns` | Privacy tags, skeleton projects |
| `plugins` | Recommended plugin stack with install commands |
| `bifrost` | MCP gateway tool-selection hierarchy and Code Mode servers |
| `epistemic-rigor` | Confidence tiers, investigation requirements, anti-patterns |
| `game-dev` | Unity conventions, NVIDIA integration, shader development |
| `nexus-memory` | Cross-project memory behavior (requires Nexus) |

### Agents (deployed to `.claude/agents/` or `.github/agents/`)

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Post-change quality review (bugs, security, coverage) |
| `security-auditor` | Auto-spawned for auth/payment/identity code |
| `doc-writer` | Technical documentation with project style matching |

### Hooks (installed to `~/.claude/hooks/`, wired via `hooks.json`)

| Hook | Event | What It Does |
|------|-------|-------------|
| `memory-persistence/session-start` | SessionStart | Injects prior session notes + file change log |
| `mcp-health/health-check` | SessionStart | Verifies MCP servers are reachable |
| `quality-gates/git-safety` | PreToolUse(Bash) | Blocks dangerous git operations |
| `quality-gates/dev-server-block` | PreToolUse(Bash) | Blocks hanging dev server commands |
| `quality-gates/conventional-commits` | PreToolUse(Bash) | Validates commit message format |
| `quality-gates/secret-scanner` | PreToolUse(Bash) | Blocks commits with hardcoded secrets |
| `quality-gates/config-protection` | PreToolUse(Edit/Write) | Blocks edits to linter/formatter configs |
| `quality-gates/tdd-gate` | PreToolUse(Edit/Write) | Enforces test-first (strict profile only) |
| `strategic-compact/suggest-compact` | PreToolUse(Edit/Write) | Suggests compaction at logical intervals |
| `auto-format/format-on-edit` | PostToolUse(Edit/Write) | Runs prettier/black/gofmt after file edits |
| `memory-persistence/save-observation` | PostToolUse(Edit/Write) | Logs changed file paths for next session |
| `quality-gates/console-warn` | PostToolUse(Edit/Write) | Warns on console.log in edited files |
| `memory-persistence/pre-compact` | PreCompact | Marks session file with compaction timestamp |
| _prompt_ | PreCompact | Prompts Claude to persist notes before compaction |
| _prompt_ | PostCompact | Re-orients Claude after compaction silently |
| `kill-mcp-children` | Stop | Kills orphaned MCP node/uv processes |
| `memory-persistence/session-end` | Stop | Creates/updates daily session file |
| `notifications/discord-notify` | Stop | Sends Discord notification (optional) |

### Plugins (install via `claude plugins add`)

| Plugin | Marketplace | What It Provides |
|--------|-------------|-----------------|
| `superpowers` | `claude-plugins-official` | Skills, brainstorming, TDD, git worktrees |
| `context-mode` | `context-mode` | Intelligent context management |
| `claude-hud` | `claude-hud` | Status line in terminal |
| `deep-plan` | `piercelamb-plugins` | TDD-oriented implementation planning |
| `deep-implement` | `piercelamb-plugins` | Plan execution with code review |
| `deep-project` | `piercelamb-plugins` | Project analysis |
| `code-simplifier` | `claude-plugins-official` | Post-edit code cleanup |
| `semgrep` | `claude-plugins-official` | SAST security scanning |
| `claude-code-setup` | `claude-plugins-official` | Setup automation recommender |

**Marketplace registration** (add to `settings.json` under `extraKnownMarketplaces`):
```json
"piercelamb-plugins": { "source": { "source": "github", "repo": "piercelamb/claude-plugins" } },
"context-mode":        { "source": { "source": "github", "repo": "mksglu/context-mode" } },
"claude-hud":          { "source": { "source": "github", "repo": "jarrodwatts/claude-hud" } }
```

## New Machine Setup

Complete setup in order:

### 1. Clone and install

```powershell
git clone https://github.com/MCKRUZ/claude-code-mastery "$env:USERPROFILE\.claude\skills\claude-code-mastery"
cd "$env:USERPROFILE\.claude\skills\claude-code-mastery"
.\scripts\install.ps1
```

### 2. Configure settings.json

```powershell
copy references\settings-template.json "$env:USERPROFILE\.claude\settings.json"
# Edit and replace all <PLACEHOLDER> values
```

Key env vars to set:
- `LANGFUSE_*` — observability (optional, set `TRACE_TO_LANGFUSE=false` to skip)
- `NEXUS_CLI_PATH` — cross-project memory (optional)
- `SEMGREP_APP_TOKEN` — SAST scanning (optional)
- `DISCORD_WEBHOOK_URL` — stop notifications (optional)

### 3. Install plugins

```bash
# Register custom marketplaces first (copy extraKnownMarketplaces from settings-template.json)
claude plugins add superpowers@claude-plugins-official
claude plugins add context-mode@context-mode
claude plugins add claude-hud@claude-hud
claude plugins add deep-plan@piercelamb-plugins
claude plugins add deep-implement@piercelamb-plugins
claude plugins add deep-project@piercelamb-plugins
claude plugins add code-simplifier@claude-plugins-official
claude plugins add semgrep@claude-plugins-official
claude plugins add claude-code-setup@claude-plugins-official
```

### 4. Add MCP servers

```bash
# Bifrost gateway (update IP to your server)
claude mcp add bifrost --transport sse http://matthews-mac-mini.tail2800e3.ts.net:8090/mcp

# Nexus local (after installing Nexus separately)
claude mcp add nexus-local --transport stdio node /path/to/Nexus/packages/cli/dist/index.js mcp
```

### 5. Restart Claude Code

---

## Full Power-User Setup

The APM package gives you the foundation. For the complete harness — plugins, production settings, MCP gateway, lifecycle hooks, Langfuse observability, and cross-project intelligence — see **[SETUP.md](SETUP.md)**.

| Priority | What You Get | Time |
|----------|-------------|------|
| **Essential** | Skills + plugins + global config | 10 min |
| **Recommended** | + production settings + core hooks | 20 min |
| **Power User** | + MCP gateway + memory + switchboard + DSL | 45 min |
| **Full Harness** | Complete lifecycle automation | 90 min |

## Self-Updating Knowledge Base

Say "update knowledge" or "research latest" and the skill will search official docs and community sources, appending findings to `references/knowledge-base.md`.

## Usage

- Invoke directly: `/claude-code-mastery`
- Or let Claude auto-detect from context (e.g., "set up Claude Code for my project")
- Audit your setup: "audit my Claude Code configuration"

## File Structure

```
claude-code-mastery/
├── plugin.json                    # APM plugin manifest
├── apm.yml                        # APM dependency manifest
├── SKILL.md                       # Core skill (7 pillars)
├── instructions/                  # APM instructions (.instructions.md) → ~/.claude/rules/
│   ├── coding-style, security, testing, agents
│   ├── performance, patterns, plugins
│   ├── bifrost, epistemic-rigor   # MCP gateway + confidence standards
│   ├── game-dev, nexus-memory     # Domain-specific rules
├── agents/                        # APM agent definitions (.agent.md)
│   ├── code-reviewer, security-auditor, doc-writer
├── hooks.json                     # Distributable hook config ({{HOOKS_DIR}} resolved by install.ps1)
├── hooks/                         # Hook scripts → ~/.claude/hooks/
│   ├── hook-profile.ps1           # Profile system (minimal/standard/strict)
│   ├── kill-mcp-children.ps1      # Stop: clean up MCP processes
│   ├── quality-gates/             # PreToolUse safety gates
│   ├── auto-format/               # PostToolUse formatting
│   ├── memory-persistence/        # Session memory (start/end/pre-compact/observe)
│   ├── mcp-health/                # SessionStart health check
│   ├── strategic-compact/         # Compaction suggestion
│   ├── notifications/             # Discord notify (optional)
│   └── dsl/                       # Double Shot Latte autonomous hook
├── references/                    # Knowledge base & templates
│   ├── knowledge-base.md          # Living knowledge (append-only)
│   ├── settings-template.json     # Full settings.json template with placeholders
│   ├── settings-templates.md      # Prose settings guidance
│   ├── claude-md-templates.md     # CLAUDE.md templates (TS, Python, C#)
│   └── troubleshooting.md         # Common problems + fixes
├── scripts/
│   └── install.ps1                # v3.1.0 — installs hooks/rules/skills/commands
└── eval/                          # Skill evaluation framework
```

## License

MIT
