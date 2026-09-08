Perform a comprehensive health audit of the Claude Code environment. Check each category below and report findings as PASS, WARN, or FAIL. After diagnosis, offer to auto-repair any WARN/FAIL items.

The audit has two halves: **config integrity** (is everything wired correctly?) and **runtime effectiveness** (does what's wired actually behave well?). Past audits only did the first half and missed real problems — do not skip categories 3, 4, or 11.

## Known Local Overrides

Intentional local modifications the audit must verify are STILL in effect (plugin updates silently revert these):

- `plugins/cache/claude-plugins-official/semgrep/*/hooks/hooks.json` — the `inject-secure-defaults` (SessionStart) and `inject-secure-defaults-short` (UserPromptSubmit) hooks were REMOVED 2026-06-10 (they injected ~400 tokens of generic library guidance on every prompt, duplicated). If a plugin update restored them, FAIL and re-remove.

## 1. Settings Validation

- Parse `~/.claude/settings.json` and `~/.claude/settings.local.json` — valid JSON?
- Check all hook command paths exist on disk
- Check for duplicate hook entries (same script in same lifecycle event)
- **Cross-reference against plugin hooks**: for each enabled plugin, read its `plugins/cache/<marketplace>/<plugin>/<version>/hooks/hooks.json`. Flag any settings.json hook entry that points at a script a plugin already auto-registers — that script runs twice. (This exact bug existed: context-mode's sessionstart.mjs was registered in both places.)
- Verify MCP server commands are accessible (check `uv`, `node` exist)
- **Repair**: Fix invalid JSON, remove entries with missing paths, remove plugin-duplicate entries

## 2. Hook Health

- List all hooks by lifecycle event with their profile tier (minimal/standard/strict)
- Check `CLAUDE_HOOK_PROFILE` and `CLAUDE_DISABLED_HOOKS` env vars
- Verify hook-profile.ps1 and hook-profile.mjs exist and are referenced by hooks
- Flag any hooks without profile integration
- Verify hook scripts are syntactically valid (PowerShell: `[System.Management.Automation.Language.Parser]::ParseFile`; Node: `node --check`)
- **Repair**: Add missing profile integration to unguarded hooks

## 3. Runtime Injection Audit (CRITICAL — this is what static checks miss)

Actually execute the context-injecting hooks and measure what they emit:

- Run every SessionStart hook command manually (pipe empty JSON stdin: `echo '{}' |`), capture stdout
- Run every UserPromptSubmit hook the same way
- For each, report: bytes emitted, estimated tokens (bytes ÷ 4)
- **Duplicate detection**: compare outputs across all hooks in the same event AND across events — flag any repeated block of >3 identical lines (same text injected twice = pure waste)
- **Self-duplication**: within a single hook's output, flag repeated headers or paragraphs
- **Per-prompt cost**: total UserPromptSubmit emission × typical 30-prompt session = recurring overhead. Flag if any single per-prompt injection exceeds ~200 tokens — per-prompt context must earn its place far more than per-session context
- **Empty-payload check**: flag hooks that emit headers/templates with no substantive content (e.g. session template with only placeholder comments)
- **Repair**: identify the emitting script and either fix its guard logic or remove the injection

## 4. Content Cross-Reference (rules ↔ commands ↔ skills ↔ agents)

Static existence checks aren't enough — verify the *content* of config files points at things that exist:

- Grep `~/.claude/CLAUDE.md` and `~/.claude/rules/*.md` for `/command-name` references → verify each exists in `~/.claude/commands/` or as a plugin/builtin skill
- Grep the same files for skill names → verify each exists in `~/.claude/skills/` or enabled plugins
- Grep agent definitions for rules-file references → verify the files still exist at the stated paths
- Check every file in `~/.claude/rules-conditional/` is referenced by an enabled switchboard rule (orphaned conditional rules never load at all)
- Check switchboard rules.json — verify all inject_path files exist
- **Dead tooling check**: for commands whose purpose is generating artifacts (codemaps, docs, reports), verify the artifacts actually exist somewhere. A generator that has never generated is dead weight or a forgotten setup step — flag for decision
- **Repair**: fix or remove stale references, remove broken switchboard entries

## 5. Agent Inventory & Model Tiering

- Count active agents (in `~/.claude/agents/`, excluding `_archived/`); flag if >25
- Read each agent's frontmatter: report `model:` per agent
- **Tier check**: exploration/judgment agents (planner, architect, security analysis) warrant opus; structured-execution agents (build fixing, mechanical refactors, formatting) should run sonnet or below. Flag execution-type agents pinned to opus
- Flag agents with no `model:` (inherit is fine, but should be deliberate)
- **Repair**: Offer to retier or archive

## 6. Rules & Always-On Budget

- List all rule files in `~/.claude/rules/` with their FULL token cost (file bytes ÷ 4 — rules are injected in full, NOT just headers)
- Flag any rule file that is domain-specific (only relevant to a subset of projects) — candidates for `~/.claude/rules-conditional/` + switchboard injection
- Flag switchboard rules that duplicate files already in `~/.claude/rules/`
- Check for conflicting rules (two rules giving opposite guidance)
- **Repair**: move domain-specific rules to conditional injection, deduplicate

## 7. Skills Check

- List installed skills in `~/.claude/skills/` and project `.claude/skills/`
- Flag skills with broken paths or missing SKILL.md
- Flag duplicate skills (same name in global and project scope)
- **Repair**: Remove broken skill directories, flag duplicates for user decision

## 8. Memory System

- Check MEMORY.md exists and line count (<200 lines)
- Check session files directory for recent activity
- Verify the session-start empty-template guard works: take the newest sessions/*.tmp, strip HTML comments/headers/metadata — if nothing substantive remains, confirm session-start.ps1 would skip it (its `$substance` logic)
- Verify nexus-session.db exists and is accessible
- Check agentmemory MCP is configured
- Verify auto-memory directory exists and index is consistent
- **Repair**: Prune stale memory entries, rebuild index if inconsistent

## 9. Security Scan

- Check for plaintext secrets in any settings*.json files (API keys, tokens, passwords)
- Verify deny rules are in place for destructive commands
- Check that .env files are in deny list
- Scan hook scripts for command injection vulnerabilities (unquoted variables)
- **Repair**: Offer to add missing deny rules, flag secrets for rotation

## 10. Plugin Status

- List installed and enabled plugins
- Flag plugins installed but not enabled (or vice versa)
- Check plugin versions against latest available
- **Verify Known Local Overrides (top of this file) survived any plugin updates** — diff each listed file against its documented expected state
- **Repair**: Enable orphaned plugins, re-apply reverted overrides, offer to remove broken ones

## 11. Token Budget (measured, not estimated)

- Measure actual bytes of: `~/.claude/CLAUDE.md` + every `~/.claude/rules/*.md` + project CLAUDE.md. Tokens ≈ bytes ÷ 4
- Add measured SessionStart hook emission from category 3
- Add (per-prompt UserPromptSubmit emission × 30) as recurring session cost
- Add ~50 tokens per active agent description and per skill description line
- Report the total and the top 5 largest contributors individually
- Flag if total always-on overhead exceeds 15k tokens
- **Repair**: Suggest the specific largest items to trim, conditionalize, or remove

## 12. MCP Server Health

- Ping each configured MCP server endpoint
- Check Bifrost gateway connectivity and list available servers
- Verify context-mode process is running
- Check Nexus MCP accessibility
- **Repair**: Restart unresponsive local servers, report unreachable remote servers

## Report Format

```
╔══════════════════════════════════════╗
║     HARNESS HEALTH AUDIT REPORT     ║
╠══════════════════════════════════════╣
║  Score: XX/12 categories passing    ║
║  Always-on overhead: ~XX.Xk tokens  ║
║  Per-prompt overhead: ~XXX tokens   ║
║  Profile: [minimal|standard|strict] ║
║  Assessed: YYYY-MM-DD HH:MM        ║
╚══════════════════════════════════════╝

[PASS] Settings Validation
[WARN] Runtime Injection — secure-defaults block emitted twice (SessionStart + UserPromptSubmit)
[FAIL] Token Budget — rules/ alone measures 9.2k tokens (heuristic previously reported 1.1k)
...

## Auto-Repair Available
1. [Settings] Remove plugin-duplicate SessionStart entry
2. [Plugin Status] Re-apply semgrep hooks.json override (reverted by update)

Run repairs? (y/n)
```

Present results as a formatted report. After presenting findings, offer to auto-repair any fixable WARN/FAIL items. Only repair with user confirmation. When a category requires executing hook commands (category 3), run them with empty/dummy stdin and treat non-zero exits as WARN, not FAIL — some hooks legitimately need real session context.
