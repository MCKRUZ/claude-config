# Publishing targets — render to the right format for the destination

A polished web page and a Substack post are not the same artifact. Pasting styled HTML into Substack or Medium throws away every bit of the styling — they ingest a *limited* rich-text vocabulary, not CSS. So Render must know its **target** and emit the format that survives there.

## Rule zero: honor the project's conventions before inventing anything

**Before rendering for any target, look at the project.** Check `CLAUDE.md` / `AGENTS.md`, any `blog/`, `substack/`, `medium/`, `docs/` directories, existing published files, and conversion tools (`preview.html`, `*publish*.py`). If the project documents:

- a **design system** (palette, fonts, CSS variables) → match it; do not impose your own aesthetic.
- a **post template** (wrapper element, nav, related-posts, OG tags) → follow it so the output drops into the pipeline.
- an **image convention** (e.g. `[INSERT IMAGE: …]` placeholders vs. `![]()` vs. embedded) → use theirs.
- a **conversion/extraction step** (e.g. HTML→markdown that keys off a specific wrapper class) → produce output that step can consume.

A distributable skill must not bake in one project's specifics. Detect them at runtime. When the project documents nothing, fall back to the generic profile below.

## Target profiles

### Web / blog — rich styled HTML
Full self-contained styled HTML (the briefing or editorial render). This is the *only* target that carries real visual design. **If the project has a blog template and shared stylesheet, build from those** (link the shared CSS, use the project's wrapper element and component classes) rather than a standalone themed file — a standalone file won't match the site and may break downstream converters that expect a specific structure. Use a standalone self-contained file only when there is no project template or when the user explicitly wants a portable one-off.

### Substack — paste-safe markdown
Substack's editor accepts pasted rich text and keeps only: **headings (h1–h3), bold, italic, bulleted/numbered lists, blockquotes, links, and images** (no CSS, cards, custom fonts, multi-column layout). Tables are the trap — Substack's markdown converter **cannot render them**; they ship as raw `|` text. Produce **clean markdown** with section structure via `##`/`###`, emphasis via `**bold**`, and candor/caveats and stat blocks as `>` blockquotes. Visual relief comes from *rhythm*, not styling: shorter paragraphs, frequent subheads, blockquoted caveats, a pull-stat as a blockquote, images at section breaks.

**Critical: detect which Substack pipeline the project uses — they want opposite things.** Look for a manual paste tool (`preview.html`) versus an API publisher (`publish.py` / `python-substack` + `cookies.json`).

| Pipeline | Image syntax | Tables |
|---|---|---|
| **Manual paste** (`preview.html`) | `[INSERT IMAGE: caption]` placeholders — the author uploads each by hand at that spot | rendered as raw text — convert to prose or bullets |
| **API publish** (`publish.py`) | `![caption](../assets/blog-images/file.png)` — the script **auto-uploads** local images to Substack's CDN; `[INSERT IMAGE]` becomes dead text | **hard-blocked** — an API publisher typically aborts on any markdown table; render tables as images first (`assets/blog-images/…png`) and reference them with `![]()` |

If the project has both tools, ask which the user is publishing through, then match its image syntax and table handling. Never leave a markdown table in a file destined for the API path, and never leave a relative `![]()` path in one destined for manual paste (it won't resolve). When no pipeline is documented at all, default to `[INSERT IMAGE]` placeholders + prose-not-tables (safest for any manual paste).

### Medium — clean markdown, Medium idioms
Medium also strips custom styling. Its conventions (match the project's existing Medium output if present): a top `*Originally published at [site](url)*` line, `# Title`, italic series/standfirst line, a bold metadata block, `---` rules, `## ` sections, stat callouts as `>` blockquotes with an em-dash source line, inline `**bold**` emphasis, and cross-links to related posts. Diagrams are typically light-background PNGs (Medium has no dark mode). No CSS, no styled cards.

## Choosing the target

Ask the user which destination(s) they want when it isn't obvious — blog, Substack, Medium, or a portable standalone page. The same source article usually produces **different files per target**, not one file that serves all. Generate each from the same underlying content and audit, re-expressed in that target's vocabulary.
