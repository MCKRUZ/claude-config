# Plan: `fieldguide` plugin

Produced 2026-11-20 by Fable 5.2 in plan mode (read-only), from the *Anthropic Developer Field Guide*
(16 Nov 2026) and an audit of `~/.claude`. Mechanics were checked against https://code.claude.com/docs.
Spot-checked afterwards: always-loaded instructions total 47,271 bytes (CLAUDE.md 210 lines + 10 rules
with no `paths:` scoping), and `suggest-compact.ps1` does call `Get-WmiObject`.

## Top recommendation

Build a small plugin, `fieldguide`: three Node hooks, two skills, one read-only reviewer agent, in its own
GitHub repo laid out like `mck-scaffold`, so `install.ps1` picks it up with no code change. Before building,
clean up config: the biggest gap against the guide is ~47 KB of always-loaded instructions, which built-in
`/doctor prompt-audit` mostly covers. Most candidate ideas (spec interview, grill-me, writer/reviewer,
context nudges) already exist in this setup and were rejected.

## 1. Coverage audit

| Guide practice | Status today | Where | Plugin action |
|---|---|---|---|
| Self-verification, "evidence not claims" | Advice globally; enforced only in Shepherd-harnessed repos | CLAUDE.md Philosophy; `rules/development-workflow.md` Phase 4; Shepherd `stop-gate.ps1` | **Gap: global Stop evidence gate** |
| Two-correction rule | Not covered (3-strike rule is about failed attempts, not user corrections) | — | **Gap: warn-only nudge** |
| Short, pruned CLAUDE.md | Not covered; `reflect-mod` adds lines, nothing prunes | CLAUDE.md 14 KB + 33 KB unscoped rules | **Gap: Phase 0 cleanup + budget skill** |
| Compaction keeps the right things | Advice + prompt hook | CLAUDE.md "Compact Instructions"; PreCompact prompt hook | **Make deterministic (PreCompact stdout)** |
| Gap review against the plan | Advice | `/code-review` reviews the diff, not plan conformance | **Small gap: fork skill + agent** |
| Context is scarce | Partly deterministic | autocompact 40%, statusline, context-mode, `lean-worker` | None |
| Hooks for must-happen rules | Deterministic | auto-format, `git-safety.ps1`, `block-find.ps1`, `config-protection.ps1` | None |
| Reversibility guardrail | Deterministic + advice | same hooks; Autonomy Framework | None |
| Plan first; spec interview; grill me | Covered | opusplan, deep-plan, `mattpocock-skills:grilling`, `/to-spec`, mck-scaffold | None |
| Writer/reviewer separation | Covered | `/code-review`, Shepherd review-gate/grader | None |
| Test-first bug fix; grounded answers; scope | Advice | `rules/testing.md`, `rules/epistemic-rigor.md` | None (not mechanically checkable) |
| "Every harness part expires" | Not covered | `/audit` is manual | **Eval with/without delta = removal test** |

### Conflicts with the guide's "advice to unlearn"

- **Always-loaded bloat.** Docs target <200 lines per CLAUDE.md; rules without `paths` load at launch.
  `rules/mcp-servers.md` (7.4 KB) is reference material; `rules/epistemic-rigor.md` (9.6 KB) restates both gates already in CLAUDE.md.
- **Emphasis.** ALL-CAPS tokens, "(mandatory, all projects)" headings, MANDATORY/CRITICAL. Current docs: emphasis mostly makes Claude over-apply the rule; a rule that can't bend belongs in a hook.
- **Over-work lines.** "Verify at every level", mandatory 7-source research before any feature, "Never suggest stopping".
- **Internal contradiction.** "Don't narrate" vs "tool descriptions must be comprehensive" and "explain pros and cons before acting".
- **Prescriptive memory rules.** PreCompact prompt hook dictates sections; guide says explain what memory is for.
- **Judgment calls.** `"model": "opusplan"` vs "strongest model"; `skipDangerousModePermissionPrompt: true`.
- **Likely inert hook (hypothesis).** `hooks/strategic-compact/suggest-compact.ps1` uses `Get-WmiObject` (absent in pwsh 7) and emits via `Write-Host` on PreToolUse.

## 2. Plugin design

```
claude-fieldguide/
  .claude-plugin/plugin.json        name, description, version, author
  .claude-plugin/marketplace.json   single entry, "source": "./", no version field
  hooks/hooks.json                  Stop, UserPromptSubmit, PreCompact (exec form)
  hooks/evidence-gate.mjs
  hooks/correction-watch.mjs
  hooks/compact-keep.mjs
  hooks/lib/io.mjs                  stdin parse, fail-open wrapper, transcript reader, state dir
  skills/budget/SKILL.md            disable-model-invocation: true
  skills/gap-review/SKILL.md        context: fork, agent: gap-reviewer
  agents/gap-reviewer.md            tools: Read, Grep, Glob, Bash
  scripts/budget.mjs
  tests/*.test.mjs, tests/fixtures/
  evals/<case>/prompt.md, graders/*.md
```

No plugin CLAUDE.md (plugins can't load one) and no SessionStart injection (always-loaded cost).

| Component | Mechanism | Cost |
|---|---|---|
| `evidence-gate` | Stop hook | ~60–100 ms per stop; one extra turn only when it fires |
| `correction-watch` | UserPromptSubmit hook, warn-only | Node start per prompt; false positives likely |
| `compact-keep` | PreCompact command hook (stdout = compaction instructions) | Only at compaction |
| `/fieldguide:budget` | User-invoked skill | Nothing until invoked |
| `/fieldguide:gap-review` + `gap-reviewer` | Skill forked into subagent | Two descriptions in context |

- **evidence-gate:** fires when the turn edited code and no test/build/lint/typecheck ran after the last edit; asks for the output or an explicit `Not verified:` line. Skips on `stop_hook_active`, plan mode, doc-only edits, or when the project has its own `.claude/hooks/stop-gate.*` (defers to Shepherd). Fails open. Modes `FIELDGUIDE_EVIDENCE=observe|enforce|off`; honours `CLAUDE_DISABLED_HOOKS`. Never runs the test suite itself (Protect the Main Machine).
- **correction-watch:** conservative regex, per-session counter in `${CLAUDE_PLUGIN_DATA}`; on the 2nd consecutive correction, a `systemMessage` suggests `/rewind` or `/clear` and `additionalContext` asks Claude to restate its misunderstanding.
- **compact-keep:** prints `git status --short` plus a short keep-list (verify commands, decisions + reasons).
- **budget:** `scripts/budget.mjs <dir>` reports always-loaded bytes/lines per file, unscoped rules, emphasis counts; Claude classifies each block keep / path-scope / move to skill / convert to hook / delete. Points to `/doctor prompt-audit`.
- **gap-review [plan]:** fresh context checks diff vs plan; reports only correctness/requirement gaps in the important / nit / pre-existing triage.

**Rejected:** spec-interview/grill commands (4 equivalents installed); writer/reviewer agent; context-health nudge (fix or delete `suggest-compact.ps1` instead); prompt/agent-type Stop hooks (model call per stop).

## 3. Mechanics verified (code.claude.com/docs/en/…)

| Mechanic | Finding | Source |
|---|---|---|
| Manifest | `.claude-plugin/plugin.json`; default dirs `skills/`, `agents/`, `commands/`, `hooks/hooks.json` | `plugins/manifest-reference`; installed mck-scaffold |
| Plugin CLAUDE.md | Not loaded — write a skill | `plugins/components` |
| Marketplace | `plugin.json` version wins; validate warns on duplicate | `plugins/marketplace-reference` |
| Stop | `stop_hook_active`, `last_assistant_message`; block via `{"decision":"block","reason"}` or exit 2; capped at 8 continuations | `hooks` |
| UserPromptSubmit | stdout/`additionalContext` to Claude; 30 s default timeout | `hooks` |
| PreCompact | stdout becomes compaction instructions (≤10,000 chars); exit 2 blocks | `hooks` |
| Exec form | `"command":"node","args":["${CLAUDE_PLUGIN_ROOT}/hooks/x.mjs"]`, no shell quoting | `hooks`; installed i-have-adhd |
| Skill frontmatter | `disable-model-invocation`, `context: fork`, `agent`, `paths`, … | `skills` |
| Plugin agents | `permissionMode`, `hooks`, `mcpServers` ignored | `plugins/components` |
| `claude plugin eval` | v2.1.269+; `evals/<case>/prompt.md` + graders; baseline arm; native Windows refuses shell-granting cases (use WSL2/Linux CI) | `plugin-evals` |

**Not verified:** Stop `additionalContext` on 2.1.310; ordering of plugin vs settings Stop hooks; whether a
`disable-model-invocation` skill's description stays out of context; inline `!` commands as shell grants in evals.

## 4. Distribution

New repo `MCKRUZ/claude-fieldguide` as a single-plugin marketplace (like mck-scaffold). Tie-in: add
`extraKnownMarketplaces.fieldguide` and `enabledPlugins["fieldguide@fieldguide"]` to `claude/settings.json`
here; `install.ps1` section 7 and `verify.ps1` already handle the rest. Develop with `claude --plugin-dir`.
Leave the version out of `marketplace.json` (mck-scaffold has 0.11.0 vs 0.18.0 drift today).

## 5. Testing

- `node --test tests/` fixture tests spawning each hook with stdin JSON + synthetic transcript; every hook <300 ms; malformed input exits 0 silently.
- `claude plugin validate . --strict`.
- Live smoke: `claude --plugin-dir . --debug` once per hook (settles the unverified items).
- Evals for `gap-review`, `budget`, and evidence behaviour; shell-granting cases in GitHub Actions on Linux. A near-zero delta means delete the component.

## 6. Phases and open questions

- **Phase 0 (no plugin):** `/context` baseline, `/doctor prompt-audit`; add `paths:` to stack rules, move `mcp-servers.md` to a skill, dedupe epistemic-rigor vs CLAUDE.md, soften emphasis, resolve the narrate contradiction.
- **Phase 1:** repo + `evidence-gate` with fixtures; observe mode, then enforce.
- **Phase 2:** `compact-keep`, `correction-watch`; retire `suggest-compact.ps1` and the PreCompact prompt hook.
- **Phase 3:** `budget`, `gap-review`, evals, CI.
- **Phase 4:** publish, add the settings entries, shrink advice lines the hooks now enforce.

Open questions (default in bold):
1. Evidence gate: **transcript check + `Not verified:` escape** vs run a per-project verify command.
2. Location: **new `MCKRUZ/claude-fieldguide` repo** vs claude-config folder vs `mckruz` marketplace.
3. Visibility: **private until stable** vs public.
4. Phase 0: **keep both gates in CLAUDE.md, restructure the rest, you review the diff**.
5. `communication-style-stop.mjs` skips on `stop_hook_active`: **accept** vs merge both Stop hooks.
6. `correction-watch`: **build warn-only regex** vs skip (reflect-mod already classifies corrections).
7. Eval venue: **GitHub Actions on Linux** vs WSL2.
