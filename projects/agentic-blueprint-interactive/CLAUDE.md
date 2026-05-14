# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A high-fidelity interactive design prototype for "The Anatomy of an Agentic Platform" — an editorial microsite that lets readers explore a 10-layer, 46-component agentic architecture through three views (Atlas, Patterns, Example). The files in `design_handoff_agentic_blueprint/design/` are **design references**, not production code. The job is to recreate them in a production stack.

## Current State

The prototype runs via in-browser React UMD + Babel (`index.html` loads `<script type="text/babel">` tags). There is no build system, no package.json, no tests, and no bundler. To preview, open `design_handoff_agentic_blueprint/design/index.html` in a browser.

## Architecture

### Data Flow

All content lives in JS data files exposed as `window.*` globals (to be converted to ES module imports in production):

| Global | Source File | Content |
|---|---|---|
| `window.LAYERS` | `data.jsx` | 10 layers, 46 components — names, ink colors, exec/eng copy, glossary terms |
| `window.ENRICHMENT` | `enrichment.jsx` | Per-layer responsibilities, decision points, anti-patterns, KPIs |
| `window.TECH_CATALOG` | `tech-catalog.jsx` | Technology tags with pros/cons/best-for |
| `window.PATTERNS` | `patterns.jsx` | 4 orchestration topologies (Supervisor, Plan-and-Execute, Pipeline, Swarm) |
| `window.GLOSSARY` | `app.jsx` | Term definitions for glossary chips |
| `window.EXAMPLE_STEPS` | `example-data.jsx` | Step-by-step scenario walkthrough payloads |

These are the **source of truth** for all site content. Lift verbatim — do not paraphrase or re-derive.

### Views

1. **Atlas** (`atlas.jsx`, `drilldown.jsx`) — Pan/zoom orthographic architecture diagram. Click layer/component to open a Dossier drawer with animated SVG arrow. Layer regions are hand-positioned via `REGIONS` constant in `atlas.jsx`.
2. **Patterns** (`patterns.jsx`) — Four topology diagrams with long-form content. Each pattern has a pure SVG diagram rendered by `<PatternViz>`.
3. **Example** (`example.jsx`, `example-data.jsx`) — Mini-atlas + step list showing "Where's my refund?" scenario traversing the platform.

### State

All state lives in `<App>` (`app.jsx`): `view`, `theme`, `revealUpTo`, `playReveal`, `openLayer`, `openComp`, `sourceRect`, `hoveredComp`. In production, sync `view` and `(openLayer, openComp)` to the URL for shareable dossier links.

## Key Constraints

- **Do not ship** `tweaks-panel.jsx`, the `EDITMODE-BEGIN/END` block in `app.jsx`, or the `__bundler_thumbnail` template in `index.html` — these are designer tools only.
- **Pixel-faithful recreation** required — final colors, typography, spacing, motion, and interactions are all defined in the prototype.
- **All design tokens** are in `styles.css` `:root` (dark) and `[data-theme="light"]` (~2,100 lines). This is the canonical visual source.
- **No raster images or icon libraries** — all graphics are code-generated SVG. Glyphs are unicode characters.
- **Fonts**: Source Serif 4 (display), Geist (body), JetBrains Mono (code/labels). Self-host in production.
- **`--type-scale`** defaults to `1.18` — keep this as the production default.
- Respect `prefers-reduced-motion` (drop ambient flow + reveal cascade).

## Suggested Production Stack

Per the design handoff README: **Next.js (App Router) + TypeScript + Tailwind CSS** (or vanilla CSS modules). Implementation order: Atlas first (highest fidelity), then Patterns, then Example. Port `styles.css` tokens to Tailwind `@theme` or CSS custom properties. Convert data files to typed `.ts` modules under `src/data/`.
