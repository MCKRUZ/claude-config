---
name: executive-eye
description: Audit, restructure, summarize, or visually render a document so the most important information is surfaced for its actual reader. Use when the user wants to make a document "exec-ready", "surface what matters", "format for leadership", clean up a report/proposal/status update so the key points lead, find what's buried in a document, or turn a dense markdown/HTML doc into a scannable executive briefing. Triggers on /executive-eye and on phrases like "make this exec-ready", "surface what matters", "what's buried in this", "format this for leadership", "tighten this up for a busy reader".
license: MIT
metadata:
  author: Matthew Kruczek
  version: "0.1.0"
---

# Executive Eye

Look at a document the way a busy decision-maker would: in the first fifteen seconds, can they tell what this is, what it's asking of them, and what they'd be wrong to miss? Most documents fail that test — the real point is on page three, the ask is buried in a paragraph, and three trivial items get the same visual weight as the one that matters. This skill fixes that.

It works on **any markdown or HTML document**. It does not assume a domain — it infers the document's purpose and reader, then decides what "important" means *for that document*.

## The core principle

**Importance is relative to the reader, not the author.** The author knows everything and ranks by effort spent. The reader ranks by consequence to them. Every decision in this skill — what leads, what gets cut, what gets a callout — answers one question: *what does this specific reader need, in what order, to act correctly?* When in doubt about the reader, infer from the document (see `references/importance.md`); if it's genuinely ambiguous and the stakes are high, ask one question, then proceed.

## Workflow

Every invocation runs the same shape: **read → audit → offer → act**. Never skip the audit. Never transform or render without showing the audit and getting a go-ahead first.

### 1. Read & infer

Read the document with the Read tool (or accept pasted text). Then, before judging anything, establish three things — state them in one or two sentences so the user can correct you:

- **What is this?** (proposal, status report, postmortem, spec, brief, memo, README, meeting notes…)
- **Who reads it, and what decision or action do they take from it?**
- **Therefore, what matters most here?** — the 3–6 things this reader would be wrong to miss.

If you cannot answer "who reads it" from the document and the answer materially changes the output, ask **one** crisp question. Otherwise proceed with your best inference and say what you assumed.

### 2. Audit (always, inline)

Read `./prompts/audit.md` and produce a concise scorecard **in the chat** — not a file. The audit diagnoses; it does not rewrite. It names, specifically and with locations:

- **Buried lead** — the most important thing isn't first / isn't visible in the first screen.
- **Hidden ask** — what the reader must decide or do is implied, not stated, or scattered.
- **Mis-ranked weight** — trivial and critical content share the same visual/structural prominence.
- **Missing** — a reader's obvious first questions have no answer (cost, risk, owner, deadline, status, recommendation).
- **Noise** — content that doesn't serve this reader and dilutes what does.

Keep it tight and evidence-based: quote or cite the location ("the budget impact is in the 2nd-to-last bullet"). End with a one-line verdict: *can the target reader act correctly from the first screen — yes/no, and the single highest-leverage fix.*

### 3. Offer

After the audit, offer the three actions and ask which (or none). Don't assume:

- **Transform** — restructure the document *in its own format* (md→md, html→html) so the important leads, the ask is explicit, and weight matches consequence. See `./prompts/transform.md`.
- **Summarize** — produce an adaptive executive summary whose shape fits the document's genre. See `./prompts/summarize.md`.
- **Render** — produce a polished deliverable for a chosen **target** (see `./references/targets.md`): rich styled **HTML** for a web/blog page, or paste-safe **markdown** for **Substack** or **Medium** (those strip all styling). For the HTML target, two modes by genre: a **briefing** for decision documents, or an **editorial article** for essays / thought-leadership that preserves the narrative and dresses it for a skimming reader. Always honor the project's documented design system, post template, and image conventions rather than inventing them. See `./prompts/render.md`.

These compose — a common path is summarize **and** render. Let the user pick more than one.

### 4. Act

When the chosen action writes a file:

- **Always ask before overwriting** the original. Offer the alternative of a new sibling file (e.g. `report.exec.md`, `report.briefing.html`). Default to a new file if the user doesn't care.
- After writing, give a **short chat summary**: what you changed and *why*, tied back to the audit findings (e.g. "moved the funding ask to the top because it was buried in §4; cut the tooling appendix as noise for a CFO reader").
- For HTML output, report the file path and that it opens in a browser.

## Hard rules

- **Audit before acting, every time.** The value is in the diagnosis; skipping it produces generic reformatting.
- **Never invent facts.** Surfacing and restructuring only. If the document is missing something important (no owner, no cost, no deadline), that's an *audit finding*, not something you fill in. Do not fabricate numbers, dates, names, or conclusions.
- **Preserve meaning and nuance.** Restructuring must not flatten a hedged claim into a certain one, or drop a caveat that changes the decision. Surfacing the lead ≠ overstating it.
- **Importance is the reader's, not yours.** Re-read the core principle if you catch yourself ranking by how interesting something is to write.
- **Same-format unless upgrading to HTML.** Transform keeps the source format. Only Render may change md→html, and only when visual treatment genuinely helps.

## Reference files

Read these as needed — don't memorize them:

- `./prompts/audit.md` — the scorecard rubric (decision-doc lenses + an article/essay mode).
- `./prompts/transform.md` — rules for restructuring in place.
- `./prompts/summarize.md` — adaptive summary shapes per genre.
- `./prompts/render.md` — the HTML render workflow (briefing mode + editorial mode).
- `./references/targets.md` — publishing targets (web/blog HTML, Substack, Medium) and the rule to honor project conventions.
- `./references/importance.md` — how to infer reader and what "important" means per document type.
- `./references/css-patterns.md` — self-contained CSS (briefing + editorial article patterns; executive-appropriate aesthetics only).
- `./templates/briefing.html` — starting-point template for briefing render (decision docs).
- `./templates/article.html` — starting-point template for editorial render (articles / essays).
