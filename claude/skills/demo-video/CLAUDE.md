# demo-video-skill

Claude Code skill for capturing project screenshots and creating demo videos/GIFs for GitHub documentation.

## Structure

```
SKILL.md              — Skill definition (what Claude reads when invoked)
scripts/              — Helper scripts for capture workflows
  check-deps.js       — Dependency checker (ffmpeg, Playwright, PowerShell)
  screenshot-web.js   — Browser screenshot via Playwright
  screenshot-desktop.ps1 — Desktop/window screenshot via PowerShell
  record-web.js       — Browser video recording with scripted interactions
  to-gif.js           — MP4 → optimized GIF (two-pass palettegen)
  slideshow.js        — PNGs → GIF slideshow (concat demuxer)
  package.json        — Local Playwright dependency
references/           — ffmpeg cheat sheet
templates/            — README snippet templates
output/               — Generated files (gitignored)
```

## Key Dependencies

- **Playwright** — Browser automation for web app capture. Installed locally in `scripts/node_modules/`.
- **ffmpeg** — Video/GIF processing. Must be on PATH. Optional if only screenshots needed.
- **PowerShell** — Screen capture for desktop apps (Windows only).

## Install

```bash
claude skill add /path/to/demo-video-skill
```

First run will need:
```bash
cd scripts && npm install --ignore-scripts
```

## Test

Trigger with: "take a screenshot of this project", "create a demo video", "make a GIF for the README"
