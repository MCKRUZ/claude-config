#!/usr/bin/env node
'use strict';

const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');
const { requireFfmpeg } = require('./check-deps');

// ── Arg parsing ────────────────────────────────────────────────

function parseArgs(argv) {
  const args = { input: null, output: null, width: 1280, height: 720, duration: 2, maxSize: 5 };
  const raw = argv.slice(2);

  for (let i = 0; i < raw.length; i++) {
    switch (raw[i]) {
      case '--output':   args.output   = raw[++i]; break;
      case '--width':    args.width    = parseInt(raw[++i], 10); break;
      case '--height':   args.height   = parseInt(raw[++i], 10); break;
      case '--duration': args.duration = parseFloat(raw[++i]); break;
      case '--max-size': args.maxSize  = parseFloat(raw[++i]); break;
      default:
        if (!raw[i].startsWith('--') && !args.input) args.input = raw[i];
    }
  }

  if (!args.input) {
    console.error('Usage: node slideshow.js <dir-or-glob> [options]');
    console.error('Options:');
    console.error('  --output <path>     Output GIF (default: ./output/slideshow.gif)');
    console.error('  --width <px>        Output width (default: 1280)');
    console.error('  --height <px>       Output height (default: 720)');
    console.error('  --duration <sec>    Seconds per slide (default: 2)');
    console.error('  --max-size <MB>     Max file size, auto-retries (default: 5)');
    process.exit(1);
  }

  if (!args.output) {
    args.output = path.join('output', 'slideshow.gif');
  }

  return args;
}

// ── Find images ────────────────────────────────────────────────

function findImages(input) {
  // If input is a directory, find all PNGs sorted by name
  if (fs.existsSync(input) && fs.statSync(input).isDirectory()) {
    return fs.readdirSync(input)
      .filter(f => /\.(png|jpg|jpeg)$/i.test(f))
      .sort()
      .map(f => path.join(input, f));
  }

  // If input is a file path pattern, try to resolve from parent dir
  const dir = path.dirname(input);
  const pattern = path.basename(input).replace('*', '');
  if (fs.existsSync(dir)) {
    return fs.readdirSync(dir)
      .filter(f => f.includes(pattern) && /\.(png|jpg|jpeg)$/i.test(f))
      .sort()
      .map(f => path.join(dir, f));
  }

  return [];
}

// ── Build slideshow GIF ────────────────────────────────────────
// Uses concat demuxer instead of glob patterns (Windows-compatible)

function buildSlideshow(images, output, width, height, duration) {
  const outDir = path.dirname(output);
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  // Write concat file list
  const concatFile = path.join(outDir, '.concat-tmp.txt');
  const lines = images.map(img => {
    const abs = path.resolve(img).replace(/\\/g, '/');
    return `file '${abs}'\nduration ${duration}`;
  });
  // Last image needs no duration but add it as the last frame
  lines.push(`file '${path.resolve(images[images.length - 1]).replace(/\\/g, '/')}'`);
  fs.writeFileSync(concatFile, lines.join('\n'), 'utf-8');

  const palette = path.join(outDir, '.palette-tmp.png');
  const vf = `scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2:color=white`;

  // Pass 1: palette
  execFileSync('ffmpeg', [
    '-y', '-f', 'concat', '-safe', '0', '-i', concatFile,
    '-vf', `${vf},palettegen=stats_mode=single`,
    palette,
  ], { stdio: 'pipe' });

  // Pass 2: render
  execFileSync('ffmpeg', [
    '-y', '-f', 'concat', '-safe', '0', '-i', concatFile,
    '-i', palette,
    '-lavfi', `${vf}[x];[x][1:v]paletteuse`,
    '-loop', '0',
    output,
  ], { stdio: 'pipe' });

  // Clean up temp files
  try { fs.unlinkSync(concatFile); } catch { /* ignore */ }
  try { fs.unlinkSync(palette); } catch { /* ignore */ }
}

// ── Size check with auto-retry ─────────────────────────────────

const RETRY_PROFILES = [
  { width: 1280, height: 720 },
  { width: 960,  height: 540 },
  { width: 640,  height: 360 },
];

function fileSizeMB(filePath) {
  return fs.statSync(filePath).size / (1024 * 1024);
}

// ── Main ───────────────────────────────────────────────────────

function main() {
  requireFfmpeg();
  const args = parseArgs(process.argv);

  const images = findImages(args.input);
  if (images.length === 0) {
    console.error(`No images found in: ${args.input}`);
    process.exit(1);
  }
  console.log(`Found ${images.length} images`);

  // Build retry chain
  const profiles = [{ width: args.width, height: args.height }];
  for (const p of RETRY_PROFILES) {
    if (p.width < args.width) {
      profiles.push(p);
    }
  }

  for (let i = 0; i < profiles.length; i++) {
    const { width, height } = profiles[i];
    const label = i === 0 ? '' : ` (retry ${i}: ${width}x${height})`;
    console.log(`Building slideshow → ${args.output}${label}`);

    buildSlideshow(images, args.output, width, height, args.duration);
    const size = fileSizeMB(args.output);

    if (size <= args.maxSize) {
      console.log(`Slideshow saved: ${args.output} (${size.toFixed(1)}MB, ${images.length} slides)`);
      return;
    }

    console.log(`GIF is ${size.toFixed(1)}MB, exceeds ${args.maxSize}MB limit`);
    if (i === profiles.length - 1) {
      console.warn(`Could not get under ${args.maxSize}MB. Final size: ${size.toFixed(1)}MB`);
      console.log(`Slideshow saved: ${args.output}`);
      return;
    }
  }
}

main();
