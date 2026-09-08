# Context Governor — Phase 0 (instrument & baseline)

Passive instrumentation for the Context Governor. Records, per turn of real
activity, the live context gauge and whether a natural task boundary fired.
**Phase 0 changes nothing about behavior** — it only logs. Its job is to answer
the load-bearing question before any reactive logic is built:

> Do my natural stopping points (git commit / tests green / todo completed)
> actually land in the 50–70% context band often enough for the governor to
> have work to do?

Full design: `research-agent/docs/superpowers/specs/2026-06-06-context-governor-design.md`.

## Components

| File | Role |
|---|---|
| `dispatcher.sh` | The single `statusLine.command`. Fans the Claude Code status payload to **claude-hud** (visible line) **and** the gauge logger (silent). The one fragile coupling point (spec §3.4/§6). |
| `gauge-logger.mjs` | Reads the status payload on stdin; appends one JSONL record per turn of real activity. Never writes stdout, never throws. |
| `context-lab.ps1` | Toggles the pinned measurement hook-set in `settings.json` (surgical, backed up, reversible). |
| `data/gauge-<hash>.jsonl` | One record per turn. `<hash>` = first 16 hex of sha256(resolved transcript path) — one file per session. |
| `data/state-<hash>.json` | Incremental cursor: last transcript line processed, cumulative Edit\|Write count, completed-todo count. |
| `data/measurement-config.json` | Marker written by `context-lab.ps1`: active config + pinned context-mode version. |
| `backups/` | Timestamped `settings.json` backups from `context-lab.ps1` and the dispatcher wiring. |

## Gauge record schema

```jsonc
{
  "ts": "ISO8601",
  "session_hash": "16-hex",
  "transcript_path": "...",
  "model_id": "claude-opus-4-8",
  "ctx": {
    "window_size": 1000000,
    "used_percentage": 13,        // native (Claude Code v2.1.6+), may be null
    "remaining_percentage": 87,   // native, may be null
    "input_tokens": ..., "output_tokens": ...,
    "cache_read_input_tokens": ..., "cache_creation_input_tokens": ...,
    "total_used_tokens": ...,     // input + cache_read + cache_creation
    "pct_of_window": 12.75,       // total / window
    "pct_corrected_33k": 13.19    // total / (window - 33000); how close to native autocompact
  },
  "boundary": {
    "git_commit": false, "tests_ran": false, "tests_passed": null,
    "todo_completed": false, "any": false, "signals": []
  },
  "naive": { "edit_calls_total": 3, "would_fire": false },  // reconstructs suggest-compact
  "new_lines_processed": 6
}
```

`pct_corrected_33k` is the load-bearing column: raw 75% of a 200K window is ~90%
of the usable budget once the 33K autocompact buffer is removed. Both native
percentages and raw token counts are logged, so the correction can be re-derived
offline and survives older Claude Code versions where the native fields are null.

`naive.would_fire` reconstructs the baseline the governor must beat: the
`strategic-compact/suggest-compact.ps1` counter fires at 50 Edit|Write calls then
every +25 (matcher `Edit|Write`, so the logger counts Edit/Write/MultiEdit only —
not all tools).

## The measurement baseline (decided 2026-06-07): everything on

**Nothing is disabled.** The governor will run in the full normal environment,
so the baseline is measured there too — ecological validity. The rule:

- **Keep on everything the governor will *coexist* with** → `memory-persistence`,
  native compaction, `context-mode`, `agentmemory`, `nexus`, `switchboard`,
  `save-observation`. All stay. (context-mode in particular suppresses context
  growth, so it directly shapes whether boundaries reach the 50–70% band — that
  is the real environment, not contamination.)
- **Turn off only what the governor *replaces*** → just `suggest-compact`, the
  naive tool-call counter. But it is a passive console suggestion that the user
  ignores, and the logger reconstructs its would-fire points (`naive.would_fire`),
  so it is left **on** too — silencing it gains nothing.

So there is no hook-toggle step. The pre-existing `CLAUDE_DISABLED_HOOKS` value
(`ollama-delegate`) is unrelated to the governor and untouched.

`pin-baseline.ps1` records the environment (incl. the **context-mode version**)
to `data/measurement-config.json`. Because `autoUpdatesChannel: latest` is set,
context-mode will auto-update during the run; a version change alters its
context-suppression behavior and **invalidates the baseline (spec §6)**.

```powershell
pwsh ~/.claude/context-governor/pin-baseline.ps1          # pin / refresh the marker
pwsh ~/.claude/context-governor/pin-baseline.ps1 -Check   # report context-mode drift
```

## Measurement is already live

The dispatcher is wired as the `statusLine.command`, so gauge logging runs every
turn automatically — it is harmless passive instrumentation, always on. A clean
run begins at the next Claude Code restart (fresh transcript → new session file,
free of this build session's test commands). Just work normally for 1–2 weeks;
re-run `pin-baseline.ps1 -Check` occasionally to catch context-mode drift.

## Known limitations (Phase 0)

- **Boundary false positives:** `git_commit` / `tests_ran` match the command
  *string* of any `Bash` tool_use, so embedding `git commit` or `dotnet test`
  text in an unrelated command (heredocs, echoes, test fixtures) trips them.
  Acceptable for passive landscape measurement and filterable in analysis; the
  Phase 2 tier-1 detector can tighten this (require top-level command + non-error
  result).
- **`tests_passed`** is inferred from the matching tool_result's `is_error` flag,
  not from parsing pass/fail counts in the output. A test command that exits 0
  but reports failures in text would read as passed.
- One record is emitted only when the transcript advances (real activity);
  StatusLine re-renders without new turns are deduped out.

## Rollback

The dispatcher wiring and every `context-lab` toggle back up `settings.json` to
`backups/` first. To fully revert: restore the relevant backup and restart.
