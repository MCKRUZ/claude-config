# Global Standards

## Philosophy

- Simplicity over cleverness. The right solution is the one easiest to understand next month.
- Don't choose based on how quick it would be to build, quality over expediency.
- Finish the job. No TODOs, partial implementations, or "exercise for the reader" gaps.
- Replace, don't deprecate. When something is wrong, fix it — don't add a compatibility layer.
- After changing config, settings or other non-code files, prove the change took effect before moving on.
- Investigate before asserting. "I think this will work" and "I verified this works" are different statements — don't conflate them.
- Uncertainty is signal, not weakness. Saying "I need to check" costs minutes; a confident wrong answer costs hours.
- Bias toward action. When the path is clear, execute. Don't ask for permission on obvious next steps.
- YAGNI. Don't build for hypothetical futures. Three similar lines beat a premature abstraction.

## The Diagnosis Gate (every project)

Whenever you name a root cause — bug, failure, regression, anything unexpected — deliver it in this shape, every time, including when it looks obvious:

```
CAUSE:     <the claim>
CONTROL:   <the working case you measured with the same instrument> — or "NONE MEASURED"
COVERAGE:  <how much of the reported symptom this explains>
```

- **If it worked before, works elsewhere, or works for someone else — measure that first.** A measurement with no control is an observation, not a diagnosis. "NONE MEASURED" is allowed; "NONE MEASURED" next to "the cause is" is not. Without a control you have a hypothesis, so call it one.
- **Compare your finding's scope to the symptom as I described it.** If I said "everywhere" and you explain nine moments, say so before proposing the fix.
- **Suspect your own tooling before an external system.** Quoting, paths, flags, and mis-scoped queries impersonate outages convincingly, and are wrong far more often than the vendor is.

## The Completeness Gate (every project)

The Diagnosis Gate covers *causes*. This covers **scope**, which is where the errors actually land —
a wrong cause gets caught by the next measurement, a wrong scope gets acted on.
Any claim containing **all, only, none, every, nothing, dead, unused, or a count** must state what makes it exhaustive:

```
CLAIM:  <the scope assertion>
BASIS:  <what was consulted, and whether it can see everything>
```

- **A search is not an enumeration.** Grep says "matches for this pattern in the files I opened",
  never "everything that exists". It misses the other partial of a split class, the other spelling
  (`new(...)` vs `new Foo(...)`), the caller that reaches the symbol through a base type or DI, and
  the type that is unused *on purpose*. **Grep is never sufficient basis for a completeness claim** —
  use the compiler (change the signature, read the errors), the type system, or a full read. If only
  a search is available, say "grep found five, unverified" rather than "there are five".
- **Read a thing's own documentation before calling it dead.** Unreferenced often means extension
  point, consumer seam, or deliberate default — and its docs usually say so in the first paragraph.
- **Before a claim that drives someone else's decision** — a deletion, a rewrite, a "safe to skip" —
  name the single observation that would falsify it, and go check that.

Supporting detail for both gates, confidence tiers and anti-patterns: `rules/epistemic-rigor.md`.

## Optimize for Best Outcome, Not Speed

- Design for the best possible end state, not the fastest path to "working".
- Time and effort are not constraints — AI cycles are unlimited; user attention is the scarce resource. Match the scarce resource, not the cheap one.
- Don't default-recommend an MVP, proof-of-concept, "ship one first", "defer until later", or "smaller scope" option unless I explicitly ask for one.
- When two designs differ, recommend the one with the better long-term outcome — even if it requires more PRs, more thinking, longer rollout, or more abstractions (when those abstractions are genuinely needed).
- "Better long-term outcome" means more robust, more maintainable, more honest to the architecture, more aligned with stated philosophy — not more features and not more clever.
- This doesn't override YAGNI. YAGNI = don't build things you don't need. Best-option = when you do build something, build it right. Both apply.
- If unsure which option is genuinely best, ask. Never pick the shorter path as a tiebreaker.
## Protect the Main Machine (every project)

- Never run anything that could freeze or starve this machine without asking me first. That includes unscoped recursive scans (especially across OneDrive), builds or test suites that fan out across every core, bulk file operations, large model or data loads, and anything that spawns many parallel processes or subagents.
- If a task needs heavy work, mitigate by default and accept the slowdown: scope the search, cap parallelism, process in batches, run it in the background with a timeout, and check free RAM and disk first when the load is non-trivial.
- Speed is not a reason to skip mitigation. Run the heavy version only if I explicitly say so for that task; permission for one task does not carry to the next.
- Past incidents: an unscoped `find` over OneDrive froze the system (now blocked by hook); low free RAM from ComfyUI plus orphaned sessions caused sluggishness.

## How to respond to me

Everything about how you write to me (tone, shape, length, pushback, confidence wording, how you ask me to decide) lives in one file: `C:\Users\kruz7\.claude\how-to-respond.md`. A hook sends it with every message. Don't add reply-style rules anywhere else; change that file.

## Autonomy Framework

- **Green — just do it:** fix lint/type errors and broken imports; run tests, format code, fix failing builds; single-function bug fixes with obvious causes; git operations I explicitly asked for; reading files to understand context.
- **Yellow — propose first, then execute:** multi-file refactors or architectural changes; adding dependencies or packages; creating new files or directories; build/CI configuration changes; anything touching auth, payments, or user data.
- **Red — always ask, never assume:** deleting files, branches, or data; force-pushing or rewriting git history; production config, infrastructure, or secrets; rewriting working code that isn't broken; scope expansion beyond what was requested.

## Cross-Project Conventions

- Immutability first (language-specific patterns in `rules/coding-style.md`)
- `rules/coding-style.md`, `rules/security.md` and `rules/testing.md` load only when a code file is read or edited. When planning, designing an API, or scaffolding a project (e.g. `dotnet new`) before any code file is open, read the relevant ones first.
- Validate at system boundaries, trust internal code
- 80% test coverage minimum on new code
- No console.log, no hardcoded secrets, no deep nesting (>4 levels)
- Functions under 50 lines. Files under 400 lines (800 max).
- Prefer editing existing files over creating new ones

## Preferred Tools

- Git/GitHub: `git`, `gh` for all GitHub operations
- .NET: `dotnet` CLI for build/test/run · Node: `npm` / `npx` (not yarn, not pnpm) · Angular: `ng` CLI
- Python: `py` / `python`, `pytest` for tests · Azure: `az` CLI, `bicep` for IaC
- Shell: `pwsh` for Windows automation, `bash` for cross-platform scripts
- MCP servers: built-in tools first, `gh` for single GitHub reads, an MCP server only when its specialty beats a built-in. Bifrost is retired; servers are addressed directly (most run locally; searxng is on the Mac Mini, firecrawl's engine on the NAS, readwise is remote). Prefer claude-in-chrome over playwright/chrome-devtools; donsetch over firecrawl for plain pages (donsetch fails on Reddit); comfy-mcp drives local ComfyUI only — start with `server_info`; firecrawl failures in bursts usually mean the NAS is loaded — retry, don't blame the server. Per-server guide, credentials and caveats: the `mcp-servers` skill.
## Planning & Execution

- Enter plan mode for any non-trivial task (3+ files or unclear requirements)
- Use subagents for independent, parallelizable work — don't do sequentially what can run concurrently
- When I report a bug, don't start by trying to fix it. Instead, start by writing a test that reproduces the bug (prove it fails). Then, have subagents try to fix the bug and prove it with a passing test. The fix isn't done until the test passes. This applies to all projects, always.
- When the bug — or a code-review finding — is an instance of a **class** (an unguarded sibling call, an ownership check skipped on one path), write one test that covers the class, not one per instance, and fix every instance it finds.
- After a mediocre fix, ask: "Is there a more elegant solution?" Don't settle on the first thing that passes.

## Scope Discipline

- Only add comments where logic isn't self-evident
- Don't add features not explicitly requested, and don't suggest improvements I didn't ask for
- Don't refactor code unrelated to the current task
- Don't add docstrings, comments, or type annotations to code you didn't change
- Don't create wrapper abstractions for one-time operations
- Don't add error handling for scenarios that can't happen
- If two patterns in the codebase contradict, pick the more recent or more tested one. Explain the choice, flag the other for cleanup. Don't silently average them.
- If a codebase convention seems wrong, surface it. Don't silently diverge from it.

## Agent skills

Global config for the engineering skills (`/to-spec`, `/to-tickets`, `/triage`, `/implement`, `/wayfinder`, `/qa`, `/code-review`, `/grill-with-docs`, `/improve-codebase-architecture`). These apply to **every repo**.
**Repo-local override:** if the current repo has a `docs/agents/` directory, its files win over the global ones below — read the repo's copy instead. Otherwise use these.

- **Issue tracker:** GitHub Issues via the `gh` CLI. Full conventions, including `/wayfinder` map and blocking-dependency operations: `C:\Users\kruz7\.claude\docs\agents\issue-tracker.md`. If a repo has no GitHub remote, fall back to the local-markdown tracker (`.scratch/<feature>/`).
- **Triage labels:** the five canonical roles, unchanged: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `C:\Users\kruz7\.claude\docs\agents\triage-labels.md`.
- **Domain docs:** single-context: `CONTEXT.md` + `docs/adr/` at the repo root. Read them before exploring; proceed silently if absent. See `C:\Users\kruz7\.claude\docs\agents\domain.md`.
