# Phase 0 ledger — always-loaded instruction cleanup (2026-11-20)

Base: commit `8095f2a` (snapshot synced from live `~/.claude`). Changes are in `claude/` on this branch,
one commit per kind of change. Nothing is applied to live `~/.claude` until approved.

## Result (expected — confirm with `/context all` in a fresh session after applying)

| | Before | After |
|---|---|---|
| Always-loaded CLAUDE.md + rules | 47,271 bytes | 32,965 bytes (−30%) |
| Loaded only with code / manifest / CI files | 0 | 5,715 bytes |
| CLAUDE.md lines (doc target < 200) | 210 | 161 |

## Ledger

| Old section | Outcome |
|---|---|
| `rules/mcp-servers.md` (7.4 KB) | **Moved** to skill `skills/mcp-servers/`. Built-ins-first priority, server locations, and the four server-choice rules (claude-in-chrome, donsetch, comfy-mcp, firecrawl/NAS) **kept** as one line in CLAUDE.md. |
| `rules/security.md` | **Split**: secrets, supply chain, "if security issue found" → always-loaded `security-baseline.md` (verbatim). Validation, auth, headers, LLM rules → `security.md`, path-scoped. |
| `rules/coding-style.md`, `rules/testing.md` | **Path-scoped** to code files. CLAUDE.md now tells Claude to read them before planning/scaffolding when no code file is open. |
| `testing.md` bug-fix workflow + "class" rule | **Merged** into CLAUDE.md Planning & Execution (must load before any file is opened). |
| `epistemic-rigor.md` gate text | **Cut as duplicate** — CLAUDE.md holds the canonical gate text. Supporting detail (global-defect control, four search failure modes, instrument table, falsifiability) **kept**. |
| `development-workflow.md` Bifrost references | **Fixed** → `github`, `reddit-apify` servers. |
| CLAUDE.md Autonomy, Presenting Choices, Compact, Agent skills | **Kept**, reformatted into fewer lines. |
| Pointers in `build-error-resolver.md`, `security-reviewer.md`, `infra-reference.md` | **Updated** to the new file names and loading behaviour. |

## Intentional meaning changes (please confirm)

1. **Narration vs tool descriptions** (the contradiction): "don't narrate" now applies to *routine steps in chat*; tool descriptions stay comprehensive.
2. **Trade-offs before acting**: still required for every choice, now *scaled to stakes* — one line for trivial choices (matches the existing Presenting Choices rule).
3. **Emphasis softened** (guide: shouting makes Claude over-apply rules): "(mandatory, all projects)" → "(every project)"; NEVER/CRITICAL/STOP → normal case; "This is mandatory, not optional" removed from the research-first rule. Every rule body is unchanged.

## Not changed (Phase 2, per plan)

Per-prompt communication-style injection hook, PreCompact prompt hook, `suggest-compact.ps1`.

## Review

Independent fresh-context review compared old vs new: 17 findings. 13 fixed (4 stale/false pointers,
glob gaps, 4 restored wordings, design-time gap, MCP choice rules), 4 kept as the intentional changes above.

## Phase 4 addendum (2026-11-22): advice the plugin now enforces

The fieldguide evidence gate now runs in enforce mode, and compact-keep runs on every compaction. Lines that only
restated what those hooks do were trimmed:

| Old text | Outcome |
|---|---|
| CLAUDE.md Philosophy: "Verify at every level. If you made a change, prove it works before moving on." | **Narrowed** to non-code changes: "After changing config, settings or other non-code files, prove the change took effect before moving on." The gate covers code edits. |
| CLAUDE.md "Compact Instructions" section | **Cut.** compact-keep hands the summarizer the request, edited files, verification state, git state, and asks it to keep decisions with reasons, user corrections and preferences, and next steps. That covers every item the section listed. |
| `development-workflow.md` Phase 4 "Show, don't claim" | **Shortened** to the part the gate does not check: keep the output of what ran (including screenshots) so PR bodies can quote it. |

**Decision (Matt, 2026-11-22):** the evidence gate covers only code-file edits followed by a recognised test, build,
lint or typecheck, not config, settings, docs or hook-registration changes. So "Verify at every level" was narrowed
to one line for non-code changes rather than cut.

If fieldguide is disabled, these three lines are the ones to restore (originals in git history of this branch).
