# Transform — restructure in place

Rewrite the document **in its own format** (markdown → markdown, HTML → HTML) so it passes the five audit lenses. This is restructuring and re-ranking, not rewriting from scratch and not adding facts.

## What transform does

- **Lead with the point.** Move the most consequential takeaway to the top. If the genre supports it, open with a short bottom-line block before any background.
- **Make the ask explicit.** State the decision or action plainly — what, who, by when — as its own clearly-marked element near the top.
- **Re-rank by consequence.** Promote what matters (its own heading, a callout, bold lead-in); demote what doesn't (later sections, appendix, or cut). Use the format's own affordances:
  - *Markdown:* heading hierarchy, a bottom-line blockquote, bolded lead-ins, tables for comparable items, `> [!IMPORTANT]`-style callouts where supported.
  - *HTML:* keep it valid and self-contained; use existing structure/classes where present rather than inventing a new design (that's Render's job).
- **Cut noise.** Remove or shrink content that doesn't serve this reader. When you cut something non-trivial, note it in the post-write summary so the user can object.
- **Tighten prose.** Replace hedging-that-hides with the actual point. Shorten without changing meaning.

## What transform must NOT do

- **No invented facts.** No new numbers, dates, owners, conclusions, or risks. Gaps are audit findings, not blanks to fill.
- **No flattening nuance.** A hedged or conditional claim stays hedged. A caveat that changes the decision stays. Surfacing ≠ overstating. If the author wrote "preliminary estimate, ±30%," the lead says so.
- **No genre violation.** Don't turn a postmortem into a sales pitch or a spec into a memo. Match the document's purpose.
- **No silent large cuts.** Trimming a sentence is fine to do quietly; removing a whole section gets called out in the summary.

## Preserve what's load-bearing

Before cutting, ask whether the content is load-bearing for *some* reader (legal language, audit trail, required disclosures, reproduction steps in a postmortem). If unsure, demote rather than delete, and flag it.

## Output

- **Ask before overwriting.** Default to a new sibling file (`<name>.exec.md` / `.exec.html`) unless the user says overwrite.
- After writing, summarize in chat: the 3–5 structural moves you made and *why*, each tied to an audit finding. Call out anything you cut or any nuance you were careful to preserve.
