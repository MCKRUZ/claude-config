#!/usr/bin/env node
'use strict';

const { execSync } = require('child_process');
const path = require('path');

// ── Probe helpers ──────────────────────────────────────────────

function probe(cmd) {
  try {
    const out = execSync(cmd, { stdio: ['pipe', 'pipe', 'pipe'], timeout: 10000 });
    return { ok: true, version: out.toString().trim().split('\n')[0] };
  } catch {
    return { ok: false, version: null };
  }
}

function checkFfmpeg() {
  const result = probe('ffmpeg -version');
  return {
    name: 'ffmpeg',
    ...result,
    install: 'winget install Gyan.FFmpeg   (or https://ffmpeg.org/download.html)',
  };
}

function checkPlaywright() {
  const result = probe('npx playwright --version');
  return {
    name: 'playwright',
    ...result,
    install: 'npx playwright install chromium',
  };
}

function checkPowerShell() {
  const result = probe('powershell -NoProfile -Command (Get-Host).Version.ToString()');
  if (result.ok && result.version) {
    result.version = `PowerShell ${result.version}`;
  }
  return {
    name: 'powershell',
    ...result,
    install: 'Built into Windows — should already be available',
  };
}

// ── Public API ─────────────────────────────────────────────────

function checkAll() {
  return [checkFfmpeg(), checkPlaywright(), checkPowerShell()];
}

function requireFfmpeg() {
  const dep = checkFfmpeg();
  if (!dep.ok) {
    throw new Error(
      `ffmpeg is required but not found on PATH.\nInstall: ${dep.install}`
    );
  }
  return dep;
}

function requirePlaywright() {
  const dep = checkPlaywright();
  if (!dep.ok) {
    throw new Error(
      `Playwright is required but not found.\nInstall: ${dep.install}`
    );
  }
  return dep;
}

// ── CLI mode ───────────────────────────────────────────────────

if (require.main === module) {
  const jsonMode = process.argv.includes('--json');
  const results = checkAll();

  if (jsonMode) {
    console.log(JSON.stringify(results, null, 2));
    process.exit(results.every(r => r.ok) ? 0 : 1);
  }

  const maxName = Math.max(...results.map(r => r.name.length));

  console.log('\nDependency Check');
  console.log('─'.repeat(60));

  for (const dep of results) {
    const status = dep.ok ? '✓' : '✗';
    const label = dep.name.padEnd(maxName + 2);
    const detail = dep.ok ? dep.version : `MISSING → ${dep.install}`;
    console.log(`  ${status}  ${label}${detail}`);
  }

  console.log('─'.repeat(60));

  const missing = results.filter(r => !r.ok);
  if (missing.length > 0) {
    console.log(`\n${missing.length} missing dependency(ies). Install before use.\n`);
    process.exit(1);
  } else {
    console.log('\nAll dependencies available.\n');
    process.exit(0);
  }
}

module.exports = { checkAll, requireFfmpeg, requirePlaywright };
