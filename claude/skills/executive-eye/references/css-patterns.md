# CSS patterns for executive briefings

## Contents

- Theme setup
- Depth tiers — encode importance with elevation
- The ask — a callout that can't be missed
- Section labels & key-point cards
- Status & risk pills
- Recessed detail with collapse (optional, vanilla JS)
- Overflow protection (always include)
- Editorial article patterns (editorial render mode)
  - Reading measure & typography
  - TL;DR / executive-read box
  - Pull quote
  - Stat / number card
  - Figure with caption / placeholder
  - Feature cards + "the catch" callout + analogy aside (breaking up walls of text)
  - Sticky section TOC (desktop sidebar, mobile collapsible)
- Don'ts

Self-contained CSS for the HTML briefing produced by Render. Everything inlines into one `<style>` block. Stay in the **executive band** (editorial, corporate-muted, blueprint, high-contrast) — sober, authoritative, high legibility. No neon, no glow, no sketch.

## Theme setup

Define light and dark via custom properties. Pick a palette that fits the chosen aesthetic; ensure both modes are legible.

```css
:root {
  --font-body: 'Inter', system-ui, -apple-system, sans-serif;
  --font-head: 'Inter', system-ui, sans-serif;   /* swap to a serif (e.g. 'Source Serif 4') for editorial */
  --font-mono: 'IBM Plex Mono', 'SF Mono', Consolas, monospace;

  --bg: #f7f7f5;
  --surface: #ffffff;
  --surface-elevated: #ffffff;
  --border: rgba(15, 23, 42, 0.10);
  --border-bright: rgba(15, 23, 42, 0.18);
  --text: #14181f;
  --text-dim: #5b6472;
  --accent: #1d4ed8;            /* one decisive accent — pick per aesthetic */
  --accent-dim: rgba(29, 78, 216, 0.08);

  /* Semantic, used sparingly for status/risk */
  --ok: #15803d;     --ok-dim: rgba(21, 128, 61, 0.10);
  --warn: #b45309;   --warn-dim: rgba(180, 83, 9, 0.10);
  --risk: #b91c1c;   --risk-dim: rgba(185, 28, 28, 0.10);
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0e1116;
    --surface: #161b22;
    --surface-elevated: #1b2230;
    --border: rgba(255, 255, 255, 0.08);
    --border-bright: rgba(255, 255, 255, 0.16);
    --text: #e6edf3;
    --text-dim: #9aa4b2;
    --accent: #60a5fa;
    --accent-dim: rgba(96, 165, 250, 0.14);
    --ok: #4ade80;   --ok-dim: rgba(74, 222, 128, 0.14);
    --warn: #fbbf24; --warn-dim: rgba(251, 191, 36, 0.14);
    --risk: #f87171; --risk-dim: rgba(248, 113, 113, 0.14);
  }
}

* { box-sizing: border-box; }
body {
  margin: 0; padding: 48px 24px;
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-body);
  line-height: 1.6;
  overflow-wrap: break-word;
}
.wrap { max-width: 860px; margin: 0 auto; }   /* briefings read better narrow */
```

## Depth tiers — encode importance with elevation

This is the core mechanism: a reader scanning for three seconds should land on the most important block because it *looks* heaviest.

```css
.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 20px 24px;
  margin: 16px 0;
}

/* Hero — the bottom line. One per page. Demands the eye. */
.card--hero {
  background: color-mix(in srgb, var(--surface) 90%, var(--accent) 10%);
  border-color: color-mix(in srgb, var(--border) 40%, var(--accent) 60%);
  box-shadow: 0 6px 28px rgba(15, 23, 42, 0.10);
  padding: 28px 32px;
}
.card--hero h1, .card--hero .bottom-line {
  font-size: clamp(1.4rem, 2.6vw, 2rem);
  font-weight: 700; line-height: 1.25; margin: 0;
}

/* Elevated — key points, the ask. Pops above the page. */
.card--elevated {
  background: var(--surface-elevated);
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.06);
}

/* Recessed — detail / appendix. Sinks back. */
.card--recessed {
  background: color-mix(in srgb, var(--bg) 60%, var(--surface) 40%);
  box-shadow: inset 0 1px 3px rgba(15, 23, 42, 0.05);
  color: var(--text-dim);
}
```

## The ask — a callout that can't be missed

```css
.ask {
  display: flex; gap: 14px; align-items: flex-start;
  border-left: 4px solid var(--accent);
  background: var(--accent-dim);
  border-radius: 0 12px 12px 0;
  padding: 18px 22px; margin: 20px 0;
}
.ask__label {
  font-family: var(--font-mono); font-size: 11px; font-weight: 600;
  text-transform: uppercase; letter-spacing: 1.5px; color: var(--accent);
}
.ask__body { font-size: 1.05rem; font-weight: 600; }
.ask__meta { color: var(--text-dim); font-weight: 400; font-size: .9rem; }
```

## Section labels & key-point cards

```css
.label {
  font-family: var(--font-mono); font-size: 10px; font-weight: 600;
  text-transform: uppercase; letter-spacing: 1.5px; color: var(--text-dim);
  margin-bottom: 8px;
}
.keypoints { display: grid; gap: 14px; grid-template-columns: 1fr; }
.keypoints--two { grid-template-columns: 1fr 1fr; }
.keypoints > * { min-width: 0; }
@media (max-width: 720px) { .keypoints--two { grid-template-columns: 1fr; } }
```

## Status & risk pills

```css
.pill {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px;
}
.pill--ok   { background: var(--ok-dim);   color: var(--ok); }
.pill--warn { background: var(--warn-dim); color: var(--warn); }
.pill--risk { background: var(--risk-dim); color: var(--risk); }
.pill--gap  { background: var(--border);   color: var(--text-dim); }  /* "not stated" gaps */
```

## Recessed detail with collapse (optional, vanilla JS)

```html
<details class="card card--recessed">
  <summary class="label" style="cursor:pointer">Full detail</summary>
  <div>…appendix content…</div>
</details>
```
`<details>` needs no JS. Reach for a script only if you want animated collapse — keep it tiny and inline.

## Overflow protection (always include)

```css
.grid > *, .flex > * { min-width: 0; }
pre, code { overflow-wrap: anywhere; }
table { width: 100%; border-collapse: collapse; }
td, th { word-break: break-word; }
img, svg, table { max-width: 100%; }
```

## Editorial article patterns (editorial render mode)

For articles/essays. Goal: a magazine feature that skims in 90 seconds and reads in full. Comfortable, confident, generous whitespace.

### Reading measure & typography

```css
.article { max-width: 720px; margin: 0 auto; }      /* ~68ch — the body column */
.article p { font-size: 1.12rem; line-height: 1.7; margin: 0 0 1.2em; }
.article h2 { font-size: clamp(1.5rem, 3vw, 2rem); margin: 2.2em 0 .6em; line-height: 1.2; }
.article h3 { font-size: 1.2rem; margin: 1.8em 0 .4em; }
.dek { font-size: clamp(1.15rem, 2.4vw, 1.5rem); line-height: 1.4; color: var(--text-dim);
  font-weight: 400; margin: .4em 0 1.6em; }              /* standfirst under the title */
.article-meta { font-family: var(--font-mono); font-size: 12px; letter-spacing: 1px;
  text-transform: uppercase; color: var(--text-dim); }
```

### TL;DR / executive-read box

```css
.tldr {
  background: var(--accent-dim);
  border: 1px solid color-mix(in srgb, var(--border) 50%, var(--accent) 50%);
  border-radius: 14px; padding: 24px 28px; margin: 28px 0 40px;
}
.tldr__label { font-family: var(--font-mono); font-size: 11px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 1.5px; color: var(--accent); margin-bottom: 12px; }
.tldr ul { margin: 0; padding-left: 20px; }
.tldr li { margin: 8px 0; line-height: 1.55; }
```

### Pull quote

```css
.pullquote {
  font-size: clamp(1.4rem, 3vw, 1.9rem); line-height: 1.3; font-weight: 600;
  color: var(--text); border-left: 4px solid var(--accent);
  padding: 6px 0 6px 24px; margin: 32px 0; max-width: 100%;
}
/* Optional: float beside text on wide screens */
@media (min-width: 1100px) {
  .pullquote--aside { float: right; width: 320px; margin: 8px -200px 24px 32px; border: none;
    border-top: 3px solid var(--accent); padding: 16px 0 0; }
}
```

### Stat / number card

```css
.stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 16px; margin: 28px 0; }
.stat { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 20px; }
.stat__num { font-size: clamp(2rem, 5vw, 3rem); font-weight: 800; line-height: 1; color: var(--accent); }
.stat__label { font-size: .9rem; color: var(--text-dim); margin-top: 8px; line-height: 1.4; }
.stat__src { font-family: var(--font-mono); font-size: 10px; color: var(--text-dim); margin-top: 10px; }
```

### Figure with caption / placeholder

```css
figure { margin: 32px 0; }
figure img { width: 100%; border-radius: 12px; border: 1px solid var(--border); }
figcaption { font-size: .88rem; color: var(--text-dim); margin-top: 10px; line-height: 1.5; }
.fig-placeholder { display: grid; place-items: center; text-align: center; min-height: 180px;
  background: color-mix(in srgb, var(--bg) 50%, var(--surface) 50%);
  border: 1px dashed var(--border-bright); border-radius: 12px; color: var(--text-dim);
  font-family: var(--font-mono); font-size: 12px; padding: 24px; }
```

### Feature cards + "the catch" callout + analogy aside (breaking up walls of text)

For parallel enumerated items (controls, features, steps) where each runs several paragraphs and ends in a caveat.

```css
/* Bounded card per enumerated item — turns one slab into N objects */
.fcard { background:var(--surface); border:1px solid var(--border); border-left:3px solid var(--accent);
  border-radius:12px; padding:4px 26px 22px; margin:24px 0; }
.fcard__n { font-family:var(--font-head); font-weight:800; font-size:.74rem; letter-spacing:1.2px;
  text-transform:uppercase; color:var(--accent); margin-top:20px; }
.fcard h3 { margin:.15em 0 .5em; }

/* "The catch" — lift each item's honest caveat into a distinct (warm) callout */
.catch { background:color-mix(in srgb, var(--warn, #b45309) 9%, var(--surface));
  border:1px solid color-mix(in srgb, var(--warn, #b45309) 32%, var(--border));
  border-radius:10px; padding:14px 18px; margin:18px 0 2px; font-size:1rem; line-height:1.6; }
.catch__label { display:block; font-family:var(--font-mono); font-size:10px; font-weight:700;
  letter-spacing:1.5px; text-transform:uppercase; color:var(--warn, #b45309); margin-bottom:6px; }

/* Analogy aside — a memory hook, set apart and lightly emphasized */
.analogy { border-left:3px solid var(--border-bright); padding:4px 0 4px 18px; margin:20px 0;
  font-style:italic; color:var(--text-dim); font-size:1.06rem; }
```

Define `--warn` in your palette (an amber/ochre that reads as "caution," distinct from the primary accent). Keep "the catch" visually consistent across every item so the reader learns to spot it.

### Sticky section TOC (desktop sidebar, mobile collapsible)

```css
.layout { display: grid; grid-template-columns: 220px minmax(0, 720px); gap: 48px;
  justify-content: center; align-items: start; }
.toc { position: sticky; top: 32px; font-size: .9rem; }
.toc a { display: block; color: var(--text-dim); text-decoration: none; padding: 4px 0;
  border-left: 2px solid transparent; padding-left: 12px; }
.toc a:hover, .toc a.active { color: var(--accent); border-left-color: var(--accent); }
@media (max-width: 980px) {
  .layout { grid-template-columns: 1fr; }
  .toc { position: static; margin-bottom: 24px; }   /* or wrap in <details> for a collapsible bar */
}
```

A few lines of vanilla JS to highlight the active TOC entry on scroll (IntersectionObserver) are acceptable and inline — keep it tiny.

## Don'ts

- No external JS frameworks, no build step, no network calls beyond at most one font `<link>`.
- No more than one accent color carrying meaning; semantic colors (ok/warn/risk) only on status.
- Don't make everything a hero — if three things shout, nothing does. One hero, a few elevated, the rest recedes.
