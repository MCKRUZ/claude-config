#!/usr/bin/env node
// Forwards a Claude Code hook event to the Jarvis HUD (http://127.0.0.1:47821/hook).
// Unlike a native "http" hook, this exits silently when the HUD is not running, so a closed
// HUD never surfaces as a hook error. When the HUD is up, its reply body goes to stdout
// unchanged (the PermissionRequest card answer travels this way).
// Usage: node jarvis-hud-forward.mjs [maxWaitSeconds]   (default 2)

import net from 'node:net';

const HOST = '127.0.0.1';
const PORT = 47821;
const maxWaitMs = (Number(process.argv[2]) || 2) * 1000;

function hudIsListening() {
  return new Promise((resolve) => {
    const socket = net.connect({ host: HOST, port: PORT });
    const done = (up) => {
      socket.destroy();
      resolve(up);
    };
    socket.setTimeout(300, () => done(false));
    socket.once('connect', () => done(true));
    socket.once('error', () => done(false));
  });
}

async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  return Buffer.concat(chunks);
}

try {
  const body = await readStdin();
  if (await hudIsListening()) {
    const res = await fetch(`http://${HOST}:${PORT}/hook`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body,
      signal: AbortSignal.timeout(maxWaitMs),
    });
    if (res.ok) {
      const reply = await res.text();
      if (reply.trim()) process.stdout.write(reply);
    }
  }
} catch {
  // HUD down, slow, or unreachable: stay silent so the hook never reports an error.
}
process.exit(0);
