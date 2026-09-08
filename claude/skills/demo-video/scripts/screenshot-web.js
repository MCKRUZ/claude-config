#!/usr/bin/env node
'use strict';

const path = require('path');
const fs = require('fs');
const { requirePlaywright } = require('./check-deps');

// ── Arg parsing ────────────────────────────────────────────────

function parseArgs(argv) {
  const args = { url: null, output: null, width: 1280, height: 720, fullPage: false, wait: 2000, waitFor: null, darkMode: false };
  const raw = argv.slice(2);

  for (let i = 0; i < raw.length; i++) {
    switch (raw[i]) {
      case '--output':    args.output   = raw[++i]; break;
      case '--width':     args.width    = parseInt(raw[++i], 10); break;
      case '--height':    args.height   = parseInt(raw[++i], 10); break;
      case '--full-page': args.fullPage = true; break;
      case '--wait':      args.wait     = parseInt(raw[++i], 10); break;
      case '--wait-for':  args.waitFor  = raw[++i]; break;
      case '--dark-mode': args.darkMode = true; break;
      default:
        if (!raw[i].startsWith('--') && !args.url) args.url = raw[i];
    }
  }

  if (!args.url) {
    console.error('Usage: node screenshot-web.js <url> [options]');
    console.error('Options:');
    console.error('  --output <path>     Output file (default: ./output/screenshot.png)');
    console.error('  --width <px>        Viewport width (default: 1280)');
    console.error('  --height <px>       Viewport height (default: 720)');
    console.error('  --full-page         Capture full scrollable page');
    console.error('  --wait <ms>         Wait before capture (default: 2000)');
    console.error('  --wait-for <sel>    Wait for CSS selector to appear');
    console.error('  --dark-mode         Use dark color scheme');
    process.exit(1);
  }

  if (!args.output) {
    args.output = path.join('output', 'screenshot.png');
  }

  return args;
}

// ── Resolve Playwright ─────────────────────────────────────────

function resolvePlaywright() {
  // Installed as local dependency in scripts/node_modules
  return require('playwright');
}

// ── Main ───────────────────────────────────────────────────────

async function main() {
  requirePlaywright();
  const args = parseArgs(process.argv);
  const playwright = resolvePlaywright();

  const outDir = path.dirname(args.output);
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  console.log(`Capturing ${args.url} → ${args.output}`);

  const browser = await playwright.chromium.launch();
  try {
    const context = await browser.newContext({
      viewport: { width: args.width, height: args.height },
      colorScheme: args.darkMode ? 'dark' : 'light',
    });
    const page = await context.newPage();
    await page.goto(args.url, { waitUntil: 'networkidle' });

    if (args.waitFor) {
      await page.waitForSelector(args.waitFor, { timeout: 10000 });
    }
    if (args.wait > 0) {
      await page.waitForTimeout(args.wait);
    }

    await page.screenshot({
      path: args.output,
      fullPage: args.fullPage,
    });

    console.log(`Screenshot saved: ${args.output}`);
    await context.close();
  } finally {
    await browser.close();
  }
}

main().catch(err => {
  console.error('Screenshot failed:', err.message);
  process.exit(1);
});
