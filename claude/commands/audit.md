# /audit — Claude Code Environment Audit

> Drop this in `~/.claude/commands/audit.md` (or as a skill). Invoke from inside the project you want audited: `/audit` or `/audit --since 14d`.

---

## Role

You are auditing this Claude Code environment on behalf of the user. Your job is to find out **why Claude forgets context, skips workflow steps, and burns effort**, and to prove each finding with evidence before proposing a fix. You are an investigator, not a fixer: you produce a report and a review branch, and you change nothing on `main`.

The user's environment is heavily customized (hooks, subagents, path-scoped rules, a 9-phase / 7-gate SDLC plugin, `kit` loadouts, Context Governor, Langfuse tracing, Windows + PowerShell, no WSL). Assume every piece of it might be misconfigured, unloaded, silently failing, or fighting another piece. Existence of a config is not evidence it works.

## Scope of this run

1. **Global:** `$env:USERPROFILE\.claude\` — `settings.json`, `CLAUDE.md`, `commands/`, `agents/`, `skills/`, `hooks/`, `plugins/`, memory files, and `projects/<encoded-path>/*.jsonl` transcripts.
2. **This project:** `.claude/` (settings, `settings.local.json`, agents, rules, hooks, skills), `CLAUDE.md` at every level, `AGENTS.md`, `.mcp.json`, and any `kit` loadout or plugin manifests in effect.
3. **Evidence sources:** session transcripts for this project (default: last 14 days, or `--since`), Langfuse traces via MCP if available, hook logs, git history of `.claude/` and `CLAUDE.md`.

Read-only until Phase 7. Never edit config, run destructive git commands, or touch `main`.

---

## Phase 0 — Inventory (what is actually loaded)

Build the effective configuration as Claude Code sees it at session start, not as the files suggest.

- Resolve settings precedence: managed → global `settings.json` → project `settings.json` → `settings.local.json`. Flag any key overridden more than once and say which wins.
- List every CLAUDE.md in the hierarchy (global → repo root → subdirectories), resolve `@` imports, and compute **total injected tokens at session start**. Flag anything over ~1.5k tokens per file or ~5k total as a continuity risk.
- List MCP servers from every source (global, project `.mcp.json`, plugin-provided, `kit` loadout). For each: enabled? reachable? how many tools does it expose? Estimate schema tokens loaded per turn.
- List hooks by event (`SessionStart`, `PreToolUse`, `PostToolUse`, `PreCompact`, `Stop`, `SubagentStop`, `Notification`). Record matcher, command, and whether the command file exists and is executable under PowerShell.
- List agents, skills, commands, plugins, and `kit` phase loadouts. Flag duplicates across global/project/plugin (same name, different content = ambiguity).
- Record the active model, thinking setting, and permission mode.

Output a single inventory table. This is the ground truth for every later phase.

---

## Phase 0.5 — System reconstruction (explain this project to its owner)

Before judging anything, produce a plain-language description of how work is *supposed* to flow in this project, and a second description of how it has *actually* flowed. The user needs to be able to read these two and decide whether the design still makes sense.

### 0.5a. Declared system — from configs

Write a **Workflow Map** the user could hand to a new engineer:

- Entry points: which commands/skills start work (`/spec`, `/plan`, `/implement`, loop skills, `kit` phase switches). For each: what it reads, what it writes, what it hands off to.
- Phase flow: the SDLC phases in order, the artifact each produces, the gate that ends it, who enforces the gate (Claude, hook, subagent, user).
- Delegation tree: which agents call which, the handoff contract (what the caller passes, what the callee must return), and where results are persisted.
- Skills by role: for each skill, the one sentence it exists to do, what triggers it, and what it depends on (MCP, hook, file convention).
- Memory model: where durable instructions live, where working state lives, what loads at `SessionStart`, what survives compaction.
- Guardrails: hooks and rules, expressed as "when X happens, Y is blocked/run/checked."

Render it as a Mermaid flowchart plus a table. Mark every node whose behavior you inferred rather than read (`[inferred]`).

### 0.5b. Historical system — from git, ADRs, and transcripts

Reconstruct how the process evolved, so the audit judges the *current* design against *everything that was learned*, not just its own docs:

- `git log` on `CLAUDE.md`, `.claude/**`, `AGENTS.md`, ADRs, and plugin/skill files. Build a timeline: what was added, removed, or reworded, and (from commit messages, ADRs, transcripts) why.
- Extract every **decision** and **learning** recorded anywhere: ADRs, `## Learnings` sections, memory files, GOLD-STANDARD docs, retro notes, and user statements in transcripts of the form "we tried X, it didn't work," "always do Y," "never Z again." List each with source and date.
- For each decision/learning, check: is it **encoded** in the current config (rule, hook, skill, CLAUDE.md line)? Or is it **orphaned** — learned once, never operationalized, and therefore forgotten? Orphaned learnings are the highest-value findings in this audit.
- Detect **regressions**: rules or hooks that existed, were removed or weakened, and whose absence corresponds to a problem that returned in later transcripts.
- Detect **dead weight**: configs added for a situation that no longer exists (old stack, abandoned agent, retired phase). Cite the last transcript where it was relevant.

### 0.5c. Fit check

For each workflow, skill, and agent in 0.5a, answer three questions with evidence:

1. **Does it still make sense?** Is the problem it was built for still present in recent history?
2. **Is it complete?** Does it incorporate every relevant learning from 0.5b, or are there orphaned learnings that belong inside it?
3. **Is it coherent?** Does it overlap or conflict with another workflow/skill (two ways to plan, two loop patterns, two places state is written)?

Produce a **Workflow Fit Table**: workflow → purpose → still needed (Y/N + why) → missing learnings → conflicts → recommendation (keep / merge / retire / rewrite).

---

## Phase 1 — Memory & continuity (the "forgetting" audit)

### 1a. Across sessions

- For each CLAUDE.md and memory file: is it **instructions** (durable rules) or **state** (what we did last time)? State stuffed into CLAUDE.md goes stale and pollutes every session. Flag it.
- Check whether the project has a designated place for working state (progress file, ADRs, `.claude/memory/`, task file) and whether `SessionStart` actually loads it. If state exists but nothing injects it, that is a root cause of cross-session amnesia.
- Read the last 10 transcripts. For each session start, note what the user had to re-explain in their first 1–3 messages. Anything re-explained in ≥3 sessions is a **missing durable instruction** — list the exact phrasing so it can be promoted into CLAUDE.md or a rule.
- Check that `CLAUDE.md` rules are phrased as testable imperatives. Vague rules ("follow best practices", "be careful with architecture") are unenforceable; flag them.
- Check path-scoped rules: does each rule's glob actually match files that were edited in recent transcripts? A rule whose path never matched in 14 days is either dead or mis-globbed.

### 1b. Within a session (compaction drift)

- Find every compaction event in the transcripts. For each, compare Claude's behavior in the 10 turns before vs. after: did it re-read files it already had, ask a question already answered, drop a constraint the user stated earlier, or restart a phase?
- Check whether a `PreCompact` hook exists and what it preserves. Check whether Context Governor is actually the thing triggering compaction or whether the built-in counter is still firing first (look for which appears in the transcript).
- Check whether the compaction summary instructions (if customized) name the SDLC phase, current gate, open decisions, and files in flight. If the summary template does not carry these, the workflow will reset after every compaction.
- Measure: average tool calls per session, average turns to first compaction, and the token cost of MCP tool schemas as a share of context. If schemas are >15% of the window, compaction happens too early and forgetting is a symptom of tool bloat.

---

## Phase 2 — Workflow adherence (SDLC phases and gates)

Treat the SDLC plugin's phases and gates as a spec and test the transcripts against it.

- Extract the declared phase order and each gate's pass criteria from the plugin.
- For each transcript, reconstruct the phase sequence Claude actually followed (look for phase markers, command invocations, subagent calls, gate checks). Produce a **declared vs. observed** table per session.
- Classify every deviation:
  - **Skipped gate** — moved to next phase without the gate's check appearing in the transcript.
  - **Silent gate** — gate ran but its output was never surfaced to the user.
  - **Phase restart** — phase re-entered after compaction or subagent return without carrying prior results.
  - **User-forced skip** — user told Claude to move on. Count these separately; they are workflow-design findings, not Claude-behavior findings.
- Diagnose why gates get skipped. Common root causes to check explicitly: the gate lives only in prose in CLAUDE.md with no hook or command enforcing it; the phase state is held in conversation memory instead of a file; a subagent runs the gate but its result is not written anywhere the orchestrator reads; the gate check is too expensive so Claude rationalizes past it.
- For each gate, recommend the **enforcement tier**: prose instruction (weakest) → command the user runs → `PreToolUse`/`Stop` hook that blocks (strongest). Say which gates warrant blocking hooks and what the hook should check.

---

## Phase 3 — Efficiency (redundant work and loop waste)

- **Redundant reads:** count files read more than once in a session without an intervening edit. List the top offenders and the sessions where it happened.
- **Repeated searches:** same or near-identical grep/glob/search calls within one session.
- **Retry loops:** the same tool call failing ≥2 times in a row. Identify the cause (missing tool, Windows path issue, permission denial, PowerShell vs bash mismatch).
- **Build/test churn:** builds or test runs triggered by hooks on every edit when a batch would do. Compare hook frequency to actual user-visible benefit.
- **Subagent waste:** subagents spawned that re-read the same context the parent already had; subagent results that were ignored or re-derived by the parent; nested subagent chains with no clear handoff contract.
- **Autoresearch / builder-critic loops:** for any loop-style skill, measure iterations per task and whether later iterations changed anything. A loop whose last 3 iterations produce no diff is not converging; recommend a termination criterion.
- **Tool selection:** cases where a cheaper path was available (Context7 not used for library questions; full file read where a targeted read would do; MCP tool used where a shell command would do, or vice versa).
- Produce a **cost table**: estimated tokens spent on each waste category across the sampled sessions, ranked.

---

## Phase 4 — Hooks, agents, rules: are they firing?

- For each hook, find evidence of it running in transcripts or hook logs. Hooks with zero executions in 14 days are candidates for "misconfigured matcher" or "wrong shell". Test each hook command in isolation under PowerShell and record exit code and output.
- For each agent: how often was it invoked, by whom (user vs. orchestrator), and did its output get used? An agent that is defined but never delegated to is either unnecessary or the orchestrator does not know when to call it — check whether CLAUDE.md tells Claude when to use it.
- For each rule: is it in the effective set? Does anything contradict it (global vs. project, rule vs. hook, rule vs. plugin instruction)? List contradictions verbatim with both sources.
- For `kit` loadouts: confirm the loadout for the current engagement phase is the one actually loaded; check for skills/MCPs outside the loadout still being active.

---

## Phase 5 — Tool and MCP hygiene

- MCP servers with zero tool calls in 14 days → recommend removal from default loadout (move to a `kit` phase or on-demand).
- Servers exposing >20 tools → recommend `disabledTools` / allowlist so only the used subset loads.
- Duplicate capability across servers (two ways to read files, two ways to search) → pick one, document the choice.
- Permission prompts: count how many appeared per session and which tools caused them. Repeated prompts for the same safe command are friction; recommend explicit allow entries.
- Verify Langfuse tracing is actually capturing sessions (trace count vs. transcript count). If they diverge, tracing is broken and the user is flying blind.

---

## Phase 6 — Scoring

Score each area 0–10 with a one-line justification and the single highest-leverage fix:

| Area | Score | Justification | Top fix |
|---|---|---|---|
| Cross-session continuity | | | |
| In-session continuity (compaction) | | | |
| SDLC gate enforcement | | | |
| Efficiency / loop discipline | | | |
| Hooks & agents actually firing | | | |
| Tool/MCP hygiene | | | |

Then list the **top 5 root causes**, ranked by how many findings they explain. Prefer one root cause that explains ten symptoms over ten point fixes.

---

## Phase 7 — Deliverables

1. **Report** — `.claude/audit/AUDIT-<yyyy-MM-dd>.md` containing Phases 0–6. Lead with the Phase 0.5 Workflow Map and Fit Table — the user should understand the system before reading what is wrong with it. Also write the Workflow Map to `.claude/audit/WORKFLOW-MAP.md` as a standalone doc, since it is useful beyond this audit. Every finding must cite evidence: transcript file + turn index, Langfuse trace ID, or config file + line. A finding with no evidence is a hypothesis; label it as such and put it in a separate section.
2. **Review branch** — `audit/<yyyy-MM-dd>`. Commit the proposed fixes as separate commits, one per root cause, each with a message that names the finding it addresses. Never commit to `main`. Never modify transcripts.
3. **Summary to the user** — under 300 words: the three things most responsible for forgetting and skipped gates, what the branch changes, and what you could not verify.

Fixes you may propose on the branch: CLAUDE.md restructuring (instructions vs. state split), new or corrected hooks, corrected rule globs, `PreCompact` summary template, MCP allowlists, `kit` loadout changes, agent invocation guidance, loop termination criteria.

Fixes you must **not** make: anything touching source code, tests, plugin internals from third parties, or credentials.

---

## Conduct rules

- Evidence before opinion. Quote the transcript turn or config line.
- Distinguish "Claude misbehaved" from "the config made misbehavior likely." Most findings should be the second kind.
- Distinguish "user overrode the process" from "Claude skipped the process."
- Windows/PowerShell is the runtime. Any recommended hook or command must run under PowerShell; multi-line PowerShell uses backtick continuation.
- If a source is unavailable (no Langfuse access, no transcripts older than N days), say so in the report rather than working around it silently.
- When two findings conflict (e.g., "add more hooks" vs. "hooks cause churn"), state the tradeoff and pick one.
