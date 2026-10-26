#!/usr/bin/env node
// UserPromptSubmit receipt log. Appends one line per prompt Claude Code receives, so a prompt that
// seems to vanish can be checked against a wall-clock record: a missing line means the prompt never
// reached Claude Code (terminal or queue problem); a present line means it did (hook or model problem).
// Records metadata only, never prompt text. Fails open: no error here may ever block a prompt.
// Log: C:/Users/kruz7/.claude/logs/prompt-receipts.jsonl

import { appendFileSync, mkdirSync, readFileSync } from 'node:fs';

const LOG_DIR = 'C:/Users/kruz7/.claude/logs';
const LOG_FILE = `${LOG_DIR}/prompt-receipts.jsonl`;

try {
  const raw = readFileSync(0, 'utf8');
  const payload = raw.trim() ? JSON.parse(raw) : {};
  const prompt = typeof payload.prompt === 'string' ? payload.prompt : '';
  const now = new Date();
  mkdirSync(LOG_DIR, { recursive: true });
  appendFileSync(
    LOG_FILE,
    JSON.stringify({
      local: now.toLocaleString('sv-SE', { timeZone: 'America/New_York' }),
      utc: now.toISOString(),
      session: typeof payload.session_id === 'string' ? payload.session_id.slice(0, 8) : null,
      cwd: typeof payload.cwd === 'string' ? payload.cwd : null,
      chars: prompt.length,
      slash: prompt.trimStart().startsWith('/'),
    }) + '\n',
  );
} catch {
  // fail open
}
process.exit(0);
