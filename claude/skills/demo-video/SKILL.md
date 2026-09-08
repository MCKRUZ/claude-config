---
name: demo-video
description: >
  Capture screenshots, record demo videos, and create optimized GIFs of projects for GitHub
  READMEs and documentation. Use when the user asks to take a screenshot, create a demo,
  make a GIF, record a demo video, screenshot this project, capture the app, or create
  visuals for a README. Also use when the user wants to show off a project or needs
  documentation assets.
allowed-tools: Bash, Read, Write, Glob, Grep, Agent
---

# Demo Video Skill

Capture screenshots, record demo videos, and create optimized GIFs for GitHub project documentation.

## Quick Reference

All helper scripts live in `${CLAUDE_SKILL_DIR}/scripts/`:

| Script | Purpose | Requires |
|--------|---------|----------|
| `check-deps.js` | Verify tool availability | — |
| `screenshot-web.js` | Browser screenshot via Playwright | Playwright |
| `screenshot-desktop.ps1` | Desktop/window screenshot | PowerShell |
| `record-web.js` | Browser video recording | Playwright |
| `to-gif.js` | MP4 → optimized GIF | ffmpeg |
| `slideshow.js` | PNGs → GIF slideshow | ffmpeg |

---

## Step 1: Check Dependencies

First, ensure script dependencies are installed (one-time setup):

```bash
cd "${CLAUDE_SKILL_DIR}/scripts" && npm install --ignore-scripts
```

Then run the dependency checker:

```bash
node "${CLAUDE_SKILL_DIR}/scripts/check-deps.js"
```

**Degradation strategy:**
- Playwright missing → Cannot capture web apps. Offer `npx playwright install chromium`.
- ffmpeg missing → Can still take screenshots, but no GIF/video conversion. Offer `winget install Gyan.FFmpeg`.
- Both missing → Only desktop screenshots via PowerShell work.

Do NOT block on missing ffmpeg if the user only needs screenshots.

---

## Step 2: Detect Project Type

Examine the project to determine capture method:

| Signal | Project Type | Method |
|--------|-------------|--------|
| `package.json` with `start`/`dev` script, or `angular.json`, `next.config.*`, `vite.config.*` | Web app (local server) | Browser capture |
| `.html` files in root or `public/` | Static web | Browser capture (file://) |
| `.csproj` with `Microsoft.NET.Sdk.Web` | .NET web app | Browser capture |
| `.exe`, `.ps1`, or CLI tool | Desktop/CLI app | Desktop capture |
| No UI at all | Library/API | Screenshot of docs, tests, or terminal output |

Ask the user if detection is ambiguous.

---

## Step 3: Choose Capture Method

Based on project type and available dependencies:

| Goal | Method | Script |
|------|--------|--------|
| Single web screenshot | `screenshot-web.js` | `node "${CLAUDE_SKILL_DIR}/scripts/screenshot-web.js" <url>` |
| Full-page web screenshot | `screenshot-web.js --full-page` | Add `--full-page` flag |
| Desktop/window screenshot | `screenshot-desktop.ps1` | `powershell -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/scripts/screenshot-desktop.ps1"` |
| Web interaction recording | `record-web.js` | `node "${CLAUDE_SKILL_DIR}/scripts/record-web.js" <url>` |
| MP4 to GIF | `to-gif.js` | `node "${CLAUDE_SKILL_DIR}/scripts/to-gif.js" <input.mp4>` |
| Multiple screenshots → GIF | `slideshow.js` | `node "${CLAUDE_SKILL_DIR}/scripts/slideshow.js" <dir>` |

---

## Step 4: Plan the Demo

Before capturing, confirm with the user:

1. **What to capture** — Which screens, features, or interactions?
2. **Shot list** — Ordered list of captures needed.
3. **Output format** — Screenshot (PNG), GIF, or video (MP4)?
4. **Dark mode?** — Dark backgrounds compress better in GIFs.

Present the plan and wait for confirmation before proceeding.

---

## Step 5: Capture

### Web Screenshots

```bash
node "${CLAUDE_SKILL_DIR}/scripts/screenshot-web.js" "http://localhost:3000" \
  --output "./output/screenshot.png" \
  --width 1280 --height 720 \
  --wait 2000
```

Options: `--full-page`, `--wait-for <selector>`, `--dark-mode`

### Desktop Screenshots

```bash
powershell -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/scripts/screenshot-desktop.ps1" \
  -OutputPath "./output/screenshot.png"
```

Options: `-WindowTitle "App Name"`, `-Region "x,y,w,h"`

### Web Recording

```bash
node "${CLAUDE_SKILL_DIR}/scripts/record-web.js" "http://localhost:3000" \
  --output "./output/recording.mp4" \
  --duration 10000
```

With scripted interactions:

```bash
node "${CLAUDE_SKILL_DIR}/scripts/record-web.js" "http://localhost:3000" \
  --interactions '[{"action":"click","selector":"#start"},{"action":"wait","ms":2000},{"action":"type","selector":"#search","text":"demo"}]'
```

Supported actions: `click`, `type`, `wait`, `scroll`, `navigate`, `hover`. Each accepts an optional `pause` (ms) between steps.

---

## Step 6: Post-Process

### Convert MP4 to GIF

```bash
node "${CLAUDE_SKILL_DIR}/scripts/to-gif.js" "./output/recording.mp4" \
  --output "./output/demo.gif" \
  --width 640 --fps 10 --max-size 5
```

Auto-retries with reduced settings if over `--max-size`:
- Pass 1: 640w, 10fps → Pass 2: 480w, 8fps → Pass 3: 320w, 6fps

### Create Slideshow from Screenshots

```bash
node "${CLAUDE_SKILL_DIR}/scripts/slideshow.js" "./output" \
  --output "./output/slideshow.gif" \
  --duration 2 --max-size 5
```

---

## Step 7: Deliver

After capturing, provide the user with:

1. **File locations** — List all generated files in `output/`.
2. **README snippet** — Suggest markdown for their README:

```markdown
## Demo

![Demo](./output/demo.gif)

## Screenshots

| Feature | Preview |
|---------|---------|
| Dashboard | ![Dashboard](./output/screenshot-dashboard.png) |
| Settings | ![Settings](./output/screenshot-settings.png) |
```

3. **Gitignore reminder** — If `output/` is not in `.gitignore`, suggest adding it (large binary files should not be committed). Recommend committing only the final optimized GIF/PNG.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Playwright not found | Run `npx playwright install chromium` |
| ffmpeg not found | Run `winget install Gyan.FFmpeg` then restart terminal |
| Screenshot is blank/white | Increase `--wait` or use `--wait-for` with a selector |
| GIF too large for GitHub | Reduce `--max-size` or use `--width 480 --fps 8` |
| PowerShell execution policy | Script already uses `-ExecutionPolicy Bypass` flag |
| Window capture wrong size | Use `-Region "x,y,w,h"` for precise area |
| Dark mode not applying | Site must respect `prefers-color-scheme` media query |
| Recording has no interactions | Pass `--interactions` JSON array or file path |

---

## References

- ffmpeg cheat sheet: `${CLAUDE_SKILL_DIR}/references/ffmpeg-cheatsheet.md`
- README templates: `${CLAUDE_SKILL_DIR}/templates/readme-snippets.md`
- GitHub GIF limits: <5MB for fast loading, <10MB max
- Recommended: 1280x720 for screenshots, 640px wide for GIFs, 10fps, 5-15s duration
