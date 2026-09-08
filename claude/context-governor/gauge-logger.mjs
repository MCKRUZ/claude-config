#!/usr/bin/env node
// Context Governor — Phase 0 passive gauge logger.
//
// Reads the Claude Code StatusLine payload on stdin (piped by dispatcher.sh),
// records one JSONL line per turn of real activity: the live context gauge
// (raw tokens + native percentages + a 33K-buffer-corrected view) and whether
// a natural task boundary just fired (git commit / tests / todo completed).
//
// It also reconstructs the naive baseline the governor must beat: a cumulative
// Edit|Write counter that "would clear" at 50 calls then every +25 (mirrors
// strategic-compact/suggest-compact.ps1, matcher Edit|Write at settings.json).
//
// HARD INVARIANTS (this runs on the StatusLine path):
//   * NEVER write to stdout — that would corrupt the visible statusline.
//   * NEVER throw — any failure exits silently. The gauge is best-effort.
//   * Incremental — only NEW transcript lines are scanned each turn, so cost
//     stays flat regardless of transcript size.
//
// Output: ~/.claude/context-governor/data/gauge-<sessionhash>.jsonl
// State : ~/.claude/context-governor/data/state-<sessionhash>.json

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { createHash } from 'node:crypto';

const GOV_DIR = path.join(os.homedir(), '.claude', 'context-governor');
const DATA_DIR = path.join(GOV_DIR, 'data');

// Naive baseline (suggest-compact.ps1): fires at 50 Edit|Write calls, then +25.
const NAIVE_THRESHOLD = 50;
const NAIVE_INTERVAL = 25;
// Claude Code reserves ~33K tokens as the autocompact buffer; the usable budget
// before native compaction fires is (window - 33K). Spec §4.1: fixed-token
// correction, not a percentage — accuracy holds across 200K and 1M windows.
const AUTOCOMPACT_BUFFER = 33000;

// Tools the naive Edit|Write counter increments on (matcher "Edit|Write" also
// matches "MultiEdit" as a regex substring).
const EDIT_TOOLS = new Set(['Edit', 'Write', 'MultiEdit']);
const TEST_CMD = /\b(dotnet\s+test|npm\s+(run\s+)?test|pnpm\s+test|yarn\s+test|pytest|ng\s+test|vitest|jest|go\s+test|cargo\s+test|dotnet\s+watch\s+test)\b/i;
const GIT_COMMIT_CMD = /\bgit\s+(-[^\s]+\s+)*commit\b/i;

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function readState(statePath) {
  try {
    const s = JSON.parse(fs.readFileSync(statePath, 'utf8'));
    return {
      lineCount: Number.isInteger(s.lineCount) ? s.lineCount : 0,
      editCalls: Number.isInteger(s.editCalls) ? s.editCalls : 0,
      completedCount: Number.isInteger(s.completedCount) ? s.completedCount : 0,
    };
  } catch {
    return { lineCount: 0, editCalls: 0, completedCount: 0 };
  }
}

function readNewLines(transcriptPath, prevLineCount) {
  let raw;
  try {
    raw = fs.readFileSync(transcriptPath, 'utf8');
  } catch {
    return null;
  }
  // Trailing newline produces a final empty element; drop it.
  const lines = raw.split('\n');
  if (lines.length && lines[lines.length - 1] === '') lines.pop();
  const total = lines.length;
  // If the file shrank (rotation / anomaly), reprocess from the start.
  const start = prevLineCount > total ? 0 : prevLineCount;
  return { newLines: lines.slice(start), total };
}

// Returns the highest completed-todo count seen in a TodoWrite's todo array.
function countCompleted(todos) {
  if (!Array.isArray(todos)) return null;
  let n = 0;
  for (const t of todos) {
    const s = t && typeof t.status === 'string' ? t.status.toLowerCase() : '';
    if (s === 'completed' || s === 'complete' || s === 'done') n++;
  }
  return n;
}

function scanLines(newLines, state) {
  const detect = {
    gitCommit: false,
    testsRan: false,
    testsPassed: null, // null = no test command this batch
    todoCompleted: false,
    signals: [],
    editCallCount: 0,
    completedCount: state.completedCount,
  };
  // Map tool_use id -> classification so a later tool_result can resolve outcome.
  const pendingTests = new Map(); // id -> true
  const pendingCommits = new Map(); // id -> true

  for (const line of newLines) {
    if (!line.trim()) continue;
    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }
    const content = entry && entry.message && entry.message.content;
    if (!Array.isArray(content)) continue;

    for (const block of content) {
      if (!block || typeof block !== 'object') continue;

      if (block.type === 'tool_use' && block.name) {
        const name = block.name;
        const input = block.input || {};

        if (EDIT_TOOLS.has(name)) {
          detect.editCallCount++;
        } else if (name === 'Bash' && typeof input.command === 'string') {
          const cmd = input.command;
          if (GIT_COMMIT_CMD.test(cmd) && !/--dry-run/.test(cmd)) {
            detect.gitCommit = true;
            if (block.id) pendingCommits.set(block.id, true);
          }
          if (TEST_CMD.test(cmd)) {
            detect.testsRan = true;
            if (block.id) pendingTests.set(block.id, true);
          }
        } else if (name === 'TodoWrite') {
          const c = countCompleted(input.todos);
          if (c !== null && c > detect.completedCount) {
            detect.todoCompleted = true;
            detect.completedCount = c;
          }
        } else if (name === 'TaskUpdate') {
          const st = typeof input.status === 'string' ? input.status.toLowerCase() : '';
          if (st === 'completed' || st === 'complete' || st === 'done') {
            detect.todoCompleted = true;
          }
        }
      }

      if (block.type === 'tool_result' && block.tool_use_id) {
        if (pendingTests.has(block.tool_use_id)) {
          // is_error false (or absent) => suite ran without a failing exit code.
          detect.testsPassed = block.is_error ? false : true;
        }
        // git commit outcome is informational; a non-error result confirms it.
      }
    }
  }

  detect.any = detect.gitCommit || detect.todoCompleted || detect.testsPassed === true;
  if (detect.gitCommit) detect.signals.push('git_commit');
  if (detect.testsPassed === true) detect.signals.push('tests_passed');
  else if (detect.testsRan) detect.signals.push('tests_ran');
  if (detect.todoCompleted) detect.signals.push('todo_completed');
  return detect;
}

// True if the cumulative Edit|Write count crossed a naive-clear point in (prev, curr].
function crossedNaive(prev, curr) {
  for (let n = prev + 1; n <= curr; n++) {
    if (n === NAIVE_THRESHOLD) return true;
    if (n > NAIVE_THRESHOLD && (n - NAIVE_THRESHOLD) % NAIVE_INTERVAL === 0) return true;
  }
  return false;
}

function main() {
  const raw = readStdin();
  if (!raw) return;
  let payload;
  try {
    payload = JSON.parse(raw);
  } catch {
    return;
  }

  const transcriptPath = payload.transcript_path;
  if (!transcriptPath || typeof transcriptPath !== 'string') return;

  const sessionHash = createHash('sha256')
    .update(path.resolve(transcriptPath))
    .digest('hex')
    .slice(0, 16);

  fs.mkdirSync(DATA_DIR, { recursive: true });
  const statePath = path.join(DATA_DIR, `state-${sessionHash}.json`);
  const gaugePath = path.join(DATA_DIR, `gauge-${sessionHash}.jsonl`);

  const state = readState(statePath);

  const read = readNewLines(transcriptPath, state.lineCount);
  if (!read) return;
  const { newLines, total } = read;
  // Dedupe: StatusLine re-renders many times per turn. Only record when the
  // transcript actually advanced (real activity happened).
  if (newLines.length === 0) return;

  const detect = scanLines(newLines, state);

  const cw = (payload && payload.context_window) || {};
  const usage = cw.current_usage || {};
  const windowSize = Number.isFinite(cw.context_window_size) ? cw.context_window_size : null;
  const inputT = num(usage.input_tokens);
  const outputT = num(usage.output_tokens);
  const cacheReadT = num(usage.cache_read_input_tokens);
  const cacheCreateT = num(usage.cache_creation_input_tokens);
  // Context occupancy = the input side of the next request (cache + fresh input).
  const totalUsed = (inputT || 0) + (cacheReadT || 0) + (cacheCreateT || 0);
  const pctOfWindow = windowSize ? round2((totalUsed / windowSize) * 100) : null;
  const effBudget = windowSize ? windowSize - AUTOCOMPACT_BUFFER : null;
  const pctCorrected = effBudget && effBudget > 0 ? round2((totalUsed / effBudget) * 100) : null;

  const newEditTotal = state.editCalls + detect.editCallCount;
  const naiveWouldFire = crossedNaive(state.editCalls, newEditTotal);

  const record = {
    ts: new Date().toISOString(),
    session_hash: sessionHash,
    transcript_path: transcriptPath,
    model_id: payload.model && payload.model.id ? payload.model.id : null,
    ctx: {
      window_size: windowSize,
      used_percentage: numOrNull(cw.used_percentage),
      remaining_percentage: numOrNull(cw.remaining_percentage),
      input_tokens: inputT,
      output_tokens: outputT,
      cache_read_input_tokens: cacheReadT,
      cache_creation_input_tokens: cacheCreateT,
      total_used_tokens: totalUsed,
      pct_of_window: pctOfWindow,
      pct_corrected_33k: pctCorrected,
    },
    boundary: {
      git_commit: detect.gitCommit,
      tests_ran: detect.testsRan,
      tests_passed: detect.testsPassed,
      todo_completed: detect.todoCompleted,
      any: detect.any,
      signals: detect.signals,
    },
    naive: {
      edit_calls_total: newEditTotal,
      would_fire: naiveWouldFire,
    },
    new_lines_processed: newLines.length,
  };

  fs.appendFileSync(gaugePath, JSON.stringify(record) + '\n');
  writeState(statePath, {
    lineCount: total,
    editCalls: newEditTotal,
    completedCount: detect.completedCount,
  });
}

function num(v) {
  return Number.isFinite(v) ? v : null;
}
function numOrNull(v) {
  return v === null || v === undefined ? null : Number.isFinite(v) ? v : null;
}
function round2(v) {
  return Math.round(v * 100) / 100;
}
function writeState(statePath, state) {
  try {
    fs.writeFileSync(statePath, JSON.stringify(state));
  } catch {
    /* non-fatal */
  }
}

try {
  main();
} catch {
  // Best-effort. Never break the statusline.
}
