#!/usr/bin/env node
'use strict';

const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');
const { requireFfmpeg } = require('./check-deps');

// ── Arg parsing ────────────────────────────────────────────────

function parseArgs(argv) {
  const args = { input: null, output: null, width: 640, fps: 10, maxSize: 5 };
  const raw = argv.slice(2);

  for (let i = 0; i < raw.length; i++) {
    switch (raw[i]) {
      case '--output':   args.output  = raw[++i]; break;
      case '--width':    args.width   = parseInt(raw[++i], 10); break;
      case '--fps':      args.fps     = parseInt(raw[++i], 10); break;
      case '--max-size': args.maxSize = parseFloat(raw[++i]); break;
      default:
        if (!raw[i].startsWith('--') && !args.input) args.input = raw[i];
    }
  }

  if (!args.input) {
    console.error('Usage: node to-gif.js <input.mp4> [options]');
    console.error('Options:');
    console.error('  --output <path>     Output GIF (default: ./output/demo.gif)');
    console.error('  --width <px>        GIF width (default: 640)');
    console.error('  --fps <n>           Frame rate (default: 10)');
    console.error('  --max-size <MB>     Max file size, auto-retries (default: 5)');
    process.exit(1);
  }

  if (!args.output) {
    const base = path.basename(args.input, path.extname(args.input));
    args.output = path.join('output', `${base}.gif`);
  }

  return args;
}

// ── Two-pass GIF conversion ────────────────────────────────────

function convertToGif(input, output, width, fps) {
  const outDir = path.dirname(output);
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  const palette = path.join(outDir, '.palette-tmp.png');
  const vf = `fps=${fps},scale=${width}:-1:flags=lanczos`;

  // Pass 1: Generate palette
  execFileSync('ffmpeg', [
    '-y', '-i', input,
    '-vf', `${vf},palettegen=stats_mode=diff`,
    palette,
  ], { stdio: 'pipe' });

  // Pass 2: Apply palette
  execFileSync('ffmpeg', [
    '-y', '-i', input, '-i', palette,
    '-lavfi', `${vf}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5`,
    '-loop', '0',
    output,
  ], { stdio: 'pipe' });

  // Clean up palette
  try { fs.unlinkSync(palette); } catch { /* ignore */ }
}

// ── Size check with auto-retry ─────────────────────────────────

const RETRY_PROFILES = [
  { width: 640, fps: 10 },
  { width: 480, fps: 8 },
  { width: 320, fps: 6 },
];

function fileSizeMB(filePath) {
  return fs.statSync(filePath).size / (1024 * 1024);
}

// ── Main ───────────────────────────────────────────────────────

function main() {
  requireFfmpeg();
  const args = parseArgs(process.argv);

  if (!fs.existsSync(args.input)) {
    console.error(`Input file not found: ${args.input}`);
    process.exit(1);
  }

  // Build retry chain: user settings first, then fallback profiles
  const profiles = [{ width: args.width, fps: args.fps }];
  for (const p of RETRY_PROFILES) {
    if (p.width < args.width || p.fps < args.fps) {
      profiles.push(p);
    }
  }

  for (let i = 0; i < profiles.length; i++) {
    const { width, fps } = profiles[i];
    const label = i === 0 ? '' : ` (retry ${i}: ${width}w, ${fps}fps)`;
    console.log(`Converting ${args.input} → ${args.output}${label}`);

    convertToGif(args.input, args.output, width, fps);
    const size = fileSizeMB(args.output);

    if (size <= args.maxSize) {
      console.log(`GIF saved: ${args.output} (${size.toFixed(1)}MB)`);
      return;
    }

    console.log(`GIF is ${size.toFixed(1)}MB, exceeds ${args.maxSize}MB limit`);
    if (i === profiles.length - 1) {
      console.warn(`Could not get under ${args.maxSize}MB. Final size: ${size.toFixed(1)}MB`);
      console.log(`GIF saved: ${args.output}`);
      return;
    }
  }
}

main();
