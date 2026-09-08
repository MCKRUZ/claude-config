#!/usr/bin/env node
// Context Governor — Phase 0 analyzer.
//
// Aggregates every data/gauge-<hash>.jsonl session and answers the load-bearing
// question: do natural task boundaries (git commit / tests green / todo done)
// land in the 50-70% corrected-context band often enough for the governor to
// have work to do? Also computes the spec §5.1 boundary-precision comparison
// against the naive Edit|Write counter.
//
// Usage:
//   node analyze-gauge.mjs            # print summary
//   node analyze-gauge.mjs --report  # also write data/analysis-<date>.md
//
// Reads only; never mutates the gauge logs.

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const DATA_DIR = path.join(os.homedir(), '.claude', 'context-governor', 'data');

// Bands over corrected context % (pct_corrected_33k; falls back to pct_of_window).
function band(pct) {
  if (pct === null || pct === undefined) return 'unknown';
  if (pct < 50) return 'green (<50)';
  if (pct < 70) return 'TARGET (50-70)';
  if (pct < 80) return 'high (70-80)';
  return 'red (>=80)';
}
const BAND_ORDER = ['green (<50)', 'TARGET (50-70)', 'high (70-80)', 'red (>=80)', 'unknown'];

function pctOf(rec) {
  const c = rec.ctx || {};
  return c.pct_corrected_33k ?? c.pct_of_window ?? null;
}

function loadRecords() {
  let files = [];
  try {
    files = fs.readdirSync(DATA_DIR).filter((f) => f.startsWith('gauge-') && f.endsWith('.jsonl'));
  } catch {
    return { files: [], sessions: new Map() };
  }
  const sessions = new Map(); // hash -> records[]
  for (const f of files) {
    const hash = f.slice('gauge-'.length, -'.jsonl'.length);
    const recs = [];
    let raw = '';
    try {
      raw = fs.readFileSync(path.join(DATA_DIR, f), 'utf8');
    } catch {
      continue;
    }
    for (const line of raw.split('\n')) {
      if (!line.trim()) continue;
      try {
        recs.push(JSON.parse(line));
      } catch {
        /* skip malformed */
      }
    }
    if (recs.length) sessions.set(hash, recs);
  }
  return { files, sessions };
}

function emptyBandCount() {
  const o = {};
  for (const b of BAND_ORDER) o[b] = 0;
  return o;
}

function pctInBand(counts, target) {
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  return total ? +((100 * counts[target]) / total).toFixed(1) : 0;
}

function bar(n, max, width = 24) {
  if (!max) return '';
  const filled = Math.round((n / max) * width);
  return '█'.repeat(filled) + '░'.repeat(width - filled);
}

function main() {
  const { files, sessions } = loadRecords();
  const lines = [];
  const out = (s = '') => lines.push(s);

  if (sessions.size === 0) {
    out('No gauge data found in ' + DATA_DIR);
    out('Work normally with the dispatcher wired; sessions will appear here.');
    console.log(lines.join('\n'));
    return;
  }

  let totalRecords = 0;
  let firstTs = null;
  let lastTs = null;

  // Boundary band counts, overall and per signal.
  const boundaryBands = emptyBandCount();
  const perSignalBands = { git_commit: emptyBandCount(), tests_passed: emptyBandCount(), todo_completed: emptyBandCount() };
  let boundaryEvents = 0;

  // Naive baseline (Edit|Write counter) would-fire points.
  const naiveBands = emptyBandCount();
  let naiveFires = 0;
  let naiveFiresAtBoundary = 0;

  // Did each session ever reach the target band / the band at all.
  let sessionsReaching50 = 0;
  let sessionsReachingTarget = 0;
  // Suspicious: very high boundary density (substring false positives).
  const perSessionBoundaryCounts = [];

  for (const recs of sessions.values()) {
    let maxPct = -1;
    let sessBoundaries = 0;
    for (const r of recs) {
      totalRecords++;
      if (r.ts) {
        if (!firstTs || r.ts < firstTs) firstTs = r.ts;
        if (!lastTs || r.ts > lastTs) lastTs = r.ts;
      }
      const pct = pctOf(r);
      if (pct !== null && pct > maxPct) maxPct = pct;
      const b = band(pct);
      const bd = r.boundary || {};

      if (bd.any) {
        boundaryEvents++;
        sessBoundaries++;
        boundaryBands[b]++;
        if (bd.git_commit) perSignalBands.git_commit[b]++;
        if (bd.tests_passed === true) perSignalBands.tests_passed[b]++;
        if (bd.todo_completed) perSignalBands.todo_completed[b]++;
      }

      if (r.naive && r.naive.would_fire) {
        naiveFires++;
        naiveBands[b]++;
        if (bd.any) naiveFiresAtBoundary++;
      }
    }
    if (maxPct >= 50) sessionsReaching50++;
    if (maxPct >= 50 && maxPct < 70) sessionsReachingTarget++;
    else if (maxPct >= 70) {
      /* passed through target on the way up; count it as reached */
      sessionsReachingTarget++;
    }
    perSessionBoundaryCounts.push(sessBoundaries);
  }

  out('═══ Context Governor — Phase 0 gauge analysis ═══');
  out('');
  out(`Sessions          : ${sessions.size}`);
  out(`Turn records      : ${totalRecords}`);
  out(`Date range        : ${firstTs ?? '?'}  →  ${lastTs ?? '?'}`);
  out(`Boundary events   : ${boundaryEvents}`);
  out(`Naive would-fire  : ${naiveFires}`);
  out('');

  out('── LOAD-BEARING: where do boundaries land? (corrected context %) ──');
  out('All boundary events by band:');
  const maxB = Math.max(1, ...Object.values(boundaryBands));
  for (const b of BAND_ORDER) {
    out(`  ${b.padEnd(15)} ${String(boundaryBands[b]).padStart(5)}  ${bar(boundaryBands[b], maxB)}`);
  }
  out(`  → ${pctInBand(boundaryBands, 'TARGET (50-70)')}% of boundaries land in the TARGET 50-70% band.`);
  out('');

  out('By signal (git commit = the gold boundary):');
  for (const sig of ['git_commit', 'tests_passed', 'todo_completed']) {
    const counts = perSignalBands[sig];
    const total = Object.values(counts).reduce((a, b) => a + b, 0);
    out(`  ${sig.padEnd(15)} n=${String(total).padStart(4)}  TARGET-band: ${pctInBand(counts, 'TARGET (50-70)')}%  ` +
        `[<50:${counts['green (<50)']} | 50-70:${counts['TARGET (50-70)']} | 70-80:${counts['high (70-80)']} | >=80:${counts['red (>=80)']}]`);
  }
  out('');

  out('── Do sessions even reach the band? ──');
  out(`  Sessions reaching >=50% corrected : ${sessionsReaching50}/${sessions.size}`);
  out(`  Sessions passing through 50-70%   : ${sessionsReachingTarget}/${sessions.size}`);
  out('');

  out('── BOUNDARY PRECISION (spec §5.1): governor vs naive counter ──');
  const naiveCleanRate = naiveFires ? +((100 * naiveFiresAtBoundary) / naiveFires).toFixed(1) : 0;
  out(`  Naive would-fire points coinciding with a real boundary : ${naiveFiresAtBoundary}/${naiveFires} = ${naiveCleanRate}%`);
  out('  Governor (fires only at boundaries, by construction)     : 100%');
  if (naiveCleanRate > 0) {
    out(`  → Governor clean-boundary rate is ${(100 / naiveCleanRate).toFixed(1)}× the naive counter (target >=2×).`);
  } else if (naiveFires > 0) {
    out('  → Naive counter never fires at a boundary; governor is strictly cleaner (>=2× trivially).');
  } else {
    out('  → Naive counter never reached its threshold yet (need longer sessions).');
  }
  out('');

  out('── False-positive watch (substring matches) ──');
  const sorted = [...perSessionBoundaryCounts].sort((a, b) => b - a);
  out(`  Boundary events per session (desc): ${sorted.slice(0, 10).join(', ')}${sorted.length > 10 ? ' …' : ''}`);
  out('  NOTE: git_commit/tests match command SUBSTRINGS. Sessions with abnormally many');
  out('  boundary events likely embedded that text in unrelated Bash — spot-check transcripts.');
  out('');
  out(`Files: ${files.length} gauge logs in ${DATA_DIR}`);

  const report = lines.join('\n');
  console.log(report);

  if (process.argv.includes('--report')) {
    const day = (lastTs || new Date().toISOString()).slice(0, 10);
    const reportPath = path.join(DATA_DIR, `analysis-${day}.md`);
    try {
      fs.writeFileSync(reportPath, '```\n' + report + '\n```\n');
      console.log('\nReport written: ' + reportPath);
    } catch (e) {
      console.log('\nCould not write report: ' + e.message);
    }
  }
}

try {
  main();
} catch (e) {
  console.error('analyze-gauge failed: ' + (e && e.message));
  process.exit(1);
}
