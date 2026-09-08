#!/usr/bin/env node
'use strict';

const path = require('path');
const fs = require('fs');
const { requirePlaywright } = require('./check-deps');

// ── Arg parsing ────────────────────────────────────────────────

function parseArgs(argv) {
  const args = {
    url: null, output: null, width: 1280, height: 720,
    duration: 10000, interactions: null, darkMode: false,
  };
  const raw = argv.slice(2);

  for (let i = 0; i < raw.length; i++) {
    switch (raw[i]) {
      case '--output':       args.output       = raw[++i]; break;
      case '--width':        args.width        = parseInt(raw[++i], 10); break;
      case '--height':       args.height       = parseInt(raw[++i], 10); break;
      case '--duration':     args.duration     = parseInt(raw[++i], 10); break;
      case '--interactions': args.interactions = raw[++i]; break;
      case '--dark-mode':    args.darkMode     = true; break;
      default:
        if (!raw[i].startsWith('--') && !args.url) args.url = raw[i];
    }
  }

  if (!args.url) {
    console.error('Usage: node record-web.js <url> [options]');
    console.error('Options:');
    console.error('  --output <path>          Output file (default: ./output/recording.mp4)');
    console.error('  --width <px>             Viewport width (default: 1280)');
    console.error('  --height <px>            Viewport height (default: 720)');
    console.error('  --duration <ms>          Max recording duration (default: 10000)');
    console.error('  --interactions <json>    JSON array of actions');
    console.error('  --dark-mode              Use dark color scheme');
    console.error('');
    console.error('Interaction actions:');
    console.error('  { "action": "click", "selector": "#btn" }');
    console.error('  { "action": "type", "selector": "#input", "text": "hello" }');
    console.error('  { "action": "wait", "ms": 1000 }');
    console.error('  { "action": "scroll", "y": 500 }');
    console.error('  { "action": "navigate", "url": "https://..." }');
    console.error('  { "action": "hover", "selector": ".menu" }');
    process.exit(1);
  }

  if (!args.output) {
    args.output = path.join('output', 'recording.mp4');
  }

  return args;
}

// ── Resolve Playwright ─────────────────────────────────────────

function resolvePlaywright() {
  // Installed as local dependency in scripts/node_modules
  return require('playwright');
}

// ── Execute interactions ───────────────────────────────────────

async function runInteractions(page, interactions) {
  for (const step of interactions) {
    switch (step.action) {
      case 'click':
        await page.click(step.selector);
        break;
      case 'type':
        await page.fill(step.selector, step.text || '');
        break;
      case 'wait':
        await page.waitForTimeout(step.ms || 1000);
        break;
      case 'scroll':
        await page.evaluate(y => window.scrollBy(0, y), step.y || 300);
        break;
      case 'navigate':
        await page.goto(step.url, { waitUntil: 'networkidle' });
        break;
      case 'hover':
        await page.hover(step.selector);
        break;
      default:
        console.warn(`Unknown action: ${step.action}`);
    }
    // Small pause between actions for visual clarity
    await page.waitForTimeout(step.pause || 300);
  }
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

  // Playwright records to a temp dir, we rename after
  const tempVideoDir = path.join(outDir, '.video-tmp');
  if (!fs.existsSync(tempVideoDir)) {
    fs.mkdirSync(tempVideoDir, { recursive: true });
  }

  console.log(`Recording ${args.url} → ${args.output}`);

  const browser = await playwright.chromium.launch();
  try {
    const context = await browser.newContext({
      viewport: { width: args.width, height: args.height },
      colorScheme: args.darkMode ? 'dark' : 'light',
      recordVideo: {
        dir: tempVideoDir,
        size: { width: args.width, height: args.height },
      },
    });

    const page = await context.newPage();
    await page.goto(args.url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(1000);

    // Run interactions or wait for duration
    if (args.interactions) {
      let steps;
      try {
        steps = JSON.parse(args.interactions);
      } catch {
        // Try reading as file path
        const content = fs.readFileSync(args.interactions, 'utf-8');
        steps = JSON.parse(content);
      }
      await runInteractions(page, steps);
    } else {
      await page.waitForTimeout(Math.min(args.duration, 30000));
    }

    // Close context to finalize video
    const video = page.video();
    await context.close();

    // Rename Playwright's random filename to our output
    if (video) {
      const tempPath = await video.path();
      if (fs.existsSync(tempPath)) {
        fs.renameSync(tempPath, args.output);
        console.log(`Recording saved: ${args.output}`);
      }
    }

    // Clean up temp dir
    try { fs.rmdirSync(tempVideoDir); } catch { /* may not be empty */ }
  } finally {
    await browser.close();
  }
}

main().catch(err => {
  console.error('Recording failed:', err.message);
  process.exit(1);
});
