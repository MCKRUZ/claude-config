# Render — the HTML executive briefing

Produce a polished, **self-contained** HTML file (all CSS inline in a `<style>` block, no external runtime dependencies, no build step) that presents the document so importance is encoded in the layout itself. A markdown source may be **upgraded to HTML** here.

Read `../references/css-patterns.md` for the styling system. Read it each time — don't render from memory.

## Choose the target first

**Where is this going to live?** Read `../references/targets.md` and pick the destination before anything else — a styled HTML page and a Substack post are different artifacts, and pasting HTML into Substack/Medium discards all the styling. Targets:

- **Web / blog** — rich styled HTML (the only target that carries real design). Build from the project's template + shared CSS if one exists.
- **Substack** — paste-safe markdown (headings, bold, lists, blockquotes, simple tables, `[INSERT IMAGE: …]` placeholders).
- **Medium** — clean markdown with Medium idioms.

**Honor the project's conventions** (rule zero in `targets.md`): match its design system, post template, and image convention rather than inventing your own. One source article usually yields a *different file per target*. The mode below (briefing vs editorial) and the structure guidance apply to the rich-HTML target; for Substack/Medium, express the same content and audit findings in that target's limited vocabulary.

## Choose the mode (rich-HTML target)

Render has two modes. Pick by genre — using the wrong one wrecks the result:

- **Briefing mode** — for **decision documents** (proposal, status report, postmortem, spec, memo). Atomizes content into a bottom-line + ask + ranked points. Starting template: `../templates/briefing.html`. See *The briefing structure* below.
- **Editorial mode** — for **articles, essays, thought-leadership** (blog, Substack, op-ed). **Preserves the narrative** and dresses it for a skimming executive reader. Starting template: `../templates/article.html`. See *Editorial mode* below.

If a decision doc has a strong narrative, or an article carries a real ask, you may borrow elements — but the dominant structure follows the genre. When unsure which genre, the article lenses vs. decision lenses in `audit.md` already told you; reuse that judgment.

## The briefing structure

A rendered briefing is organized by **consequence**, top to bottom:

1. **Hero / bottom line** — the single most important takeaway, large and unmissable. If a Summarize ran, its bottom line goes here.
2. **The ask** — the decision or action, as a distinct, high-prominence element (callout card). What · who · by when.
3. **Key points** — 3–6 cards ranked by importance, with visual weight (elevation, accent color, size) matching consequence. Critical items get a hero/elevated treatment; supporting items recede.
4. **Risks / open questions / gaps** — including the "not stated" gaps the audit surfaced, clearly marked as gaps rather than disguised as facts.
5. **Detail / appendix** — everything a reader *might* drill into but doesn't need up front. Visually recessed, optionally collapsed.

Encode hierarchy with the depth tiers in `css-patterns.md` (`--hero`, `--elevated`, `--recessed`). The test: a reader scanning for three seconds should land on the right thing because it *looks* the most important.

## Editorial mode — the article

For thought-leadership, the goal is a **beautifully typeset article that a busy executive can both skim in 90 seconds and read in full** — not a memo. The narrative stays whole; you add scannability *on top of* the prose. Start from `../templates/article.html`.

Structure, top to bottom:

1. **Title & dek** — the headline, and a one-line standfirst/subhead that states the thesis. Plus light meta (read time, date, category) if present in the source.
2. **Executive read / TL;DR box** — a visually distinct summary box near the top. **If the author already wrote one, honor and polish it** — keep their bullets, sharpen and rank them; do not replace it with your own. If there isn't one, generate a 3–5 bullet thesis-first summary (see `summarize.md` article shape).
3. **Sticky section navigation** — for anything over ~6 minutes' read, a TOC (sidebar on desktop, collapsible on mobile) so a skimmer can jump. See the responsive-nav pattern in `css-patterns.md`.
4. **Body** — the article's sections **in their original order**, with real heading hierarchy and generous reading measure (~65–75ch line length). Render the source's existing affordances richly:
   - **Pull quotes** — lift the 2–4 most quotable lines into large, offset pull-quote treatment beside or within the flow. Don't remove them from the prose; echo them.
   - **Stat / callout cards** — turn standout numbers and blockquoted stats into big-number cards (e.g. an "88%" that dominates its card).
   - **Tables** — style comparison/maturity tables cleanly; let them breathe full-width.
   - **Figures** — place referenced images as captioned figures (use the alt text as the caption if no caption exists). If an image file isn't available, leave a clearly-labeled figure placeholder with the caption — never drop the fact that a diagram belongs there.
   - **Key sentences** — the author's bolded thesis lines become subtle emphasis lead-ins, not shouting.
5. **Closing** — give the final thought/kicker room; if there's a strong last line, it can stand as a closing pull-quote.

### Breaking up walls of text

Long unbroken prose is where an executive reader disengages. Scan the body for structure the prose is hiding and give it visual form:

- **Parallel enumerated items** (a list of controls, features, steps, options — each several paragraphs long) → render each as a **bounded card** with a number/label, so the reader sees *N distinct objects* instead of one slab. See the feature-card pattern in `css-patterns.md`.
- **Caveats / honest limits** — when each item ends with a "the catch is…", "the honest limits…", "the reality check…" beat, lift it into a distinct **"the catch" callout** inside the item. This breaks the text *and* foregrounds candor, which is usually the piece's credibility engine — don't bury it.
- **Analogies** ("think of it like a universal power adapter…") → pull into a short **styled aside**; they're memory hooks and deserve to stand out.
- **A standout sentence per section** can become an inline emphasis lead-in or a pull-quote — but don't over-pull; one strong lift per section, not every paragraph.

Apply this only where the structure genuinely exists — don't manufacture cards for prose that's meant to flow. The test: if you find yourself scrolling past three identical-looking paragraphs, the reader will too.

What editorial mode must **not** do: invent an "ask"/owner/deadline, atomize the argument into disconnected cards, flatten the narrative into bullets, or strip the author's voice. Surfacing ≠ rewriting — the prose stays the author's; you are setting type and adding signposts.

Density: an executive editorial leans **comfortable and confident** — generous whitespace, strong type scale, restrained accent. It should feel like a well-designed magazine feature, not a dashboard.

## Aesthetic — vary, but stay in the executive band

Pick a different aesthetic per document to avoid sameness, **but only from the executive-appropriate band** — this is a briefing for a decision-maker, not a whiteboard sketch. Allowed:

- **Editorial** — serif headlines, generous whitespace, muted palette, restrained accent.
- **Corporate-muted** — clean sans-serif, soft neutral surfaces, single confident accent color.
- **Blueprint** — precise, grid-lined, technical-but-calm; good for specs and architecture briefs.
- **High-contrast briefing** — strong type hierarchy, near-black on near-white, one decisive accent.

Do **not** use: neon/glow dashboards, hand-drawn/sketch, playful gradient-mesh, or anything that reads as informal. The swap test still applies — if a generic template would look identical, you haven't designed it; but stay sober.

Match density to the reader if known: C-suite → comfortable spacing, fewer words, bigger hierarchy; technical leadership → can take tighter density and more detail.

## Rules

- **Self-contained.** Everything in one `.html` file. Inline CSS. System fonts or a single CDN font link is acceptable; no JS frameworks. A tiny bit of vanilla JS for collapse/expand of the detail section is fine.
- **Faithful.** Same no-invented-facts rule as everywhere. Gaps shown as gaps. Hedges preserved.
- **Responsive and legible.** Define light and dark palettes, wrap long content, sensible mobile fallback. See `css-patterns.md` overflow rules.
- **Accessible enough.** Real heading hierarchy, sufficient contrast, semantic elements — not div soup.

## Output

- Ask overwrite vs. new file; default to `<name>.briefing.html` (briefing mode) or `<name>.article.html` (editorial mode).
- Report the file path and that it opens in a browser. Give the short why-summary tied to audit findings.
