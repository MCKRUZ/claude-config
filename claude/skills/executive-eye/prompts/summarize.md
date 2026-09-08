# Summarize — adaptive executive summary

Produce a standalone summary a busy reader can absorb in under a minute and act on. The original is left intact. **The shape of the summary is derived from the document's genre** — do not force one fixed template onto every document.

## Pick the shape from the genre

Identify the genre, then use the matching skeleton. These are starting points, not cages — drop a section that has no content, add one the document demands.

- **Proposal / pitch** → Recommendation · Why now · Cost & what you get · Risks/unknowns · Decision needed.
- **Status report / update** → Overall status (on track / at risk / off track) · What changed since last time · Blockers & who owns them · What's next · Where you need help.
- **Postmortem / incident** → What happened & impact · Root cause · What we're changing · What's still open.
- **Spec / design doc** → What we're building & why · Key decisions and trade-offs · What's out of scope · Open questions.
- **Research / analysis** → Bottom line · Key findings (ranked) · Confidence & caveats · So what / recommended action.
- **Memo / announcement** → The point · What it means for you · What to do.
- **Meeting notes** → Decisions made · Action items (owner + date) · Open threads.
- **Article / essay / thought-leadership** → Thesis (the one idea, in a sentence) · Why it matters now · The 3–5 insights worth remembering (ranked) · The honest caveats · The closing thought. No "ask," no owner/deadline — an essay summary leaves the reader *informed and persuaded*, not assigned a task. If the piece already has an author-written "executive read" / TL;DR, build on it — sharpen and rank it, don't discard it.

If the genre isn't on this list, build a shape from first principles: lead with the bottom line, then the 3–6 things this reader must know, then what they need to do.

## Rules

- **Bottom line first.** The first line is the single most important thing, stated plainly. Never open with background.
- **Rank, don't list.** Order by consequence to the reader. A summary that preserves the original's ordering isn't a summary.
- **Stay faithful.** No invented facts; preserve hedges and caveats that change the decision. If the document is uncertain, the summary says so — false confidence is a failure.
- **Name the gaps.** If a decision-relevant fact is missing (no cost, no owner, no date), say "not stated" rather than guessing. This is useful signal for the reader.
- **Tight.** Aim for something that fits on one screen. Long enough to be complete for the decision, short enough to actually get read.

## Output

- Default to inline in chat unless the user wants it as a file or as the lead block of a Transform/Render. If writing a file, ask about overwrite vs. new file (SKILL.md step 4).
- If the summary will lead a rendered briefing, hand it to Render as the hero block.
