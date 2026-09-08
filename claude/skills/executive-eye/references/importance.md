# Inferring the reader and what "important" means

The skill never applies a fixed importance taxonomy. It infers, per document, who reads it and what they need. This file is the method for that inference.

## Step 1 — identify the genre

Genre is the strongest signal for both reader and priorities. Tells:

| Tells | Likely genre |
|---|---|
| "We recommend…", pricing, options, "approve" | Proposal / pitch |
| "On track / at risk", dates, % complete, "since last" | Status report |
| "Impact", "root cause", timeline of events | Postmortem / incident |
| "We will build", interfaces, "out of scope" | Spec / design doc |
| "Findings", citations, "the data shows" | Research / analysis |
| Short, "effective immediately", "all staff" | Memo / announcement |
| "Attendees", "action items", "discussed" | Meeting notes |
| Install steps, usage, badges | README / docs |
| Narrative argument, a thesis, "the shift is…", no owner/deadline, written to persuade or inform a broad reader | Article / essay / thought-leadership (blog, Substack, op-ed) |

## Step 2 — identify the reader and their decision

Ask: *who opens this, and what do they do as a result?* The reader's role sets what's consequential.

- **Executive / sponsor** → money, risk, timeline, the recommendation, what they must decide. They do **not** want implementation detail unless it changes the decision.
- **Technical leadership (director / architect)** → the technical bottom line, trade-offs, blockers, what's at risk — fast, but they can take depth.
- **Peer / implementer** → what changed, what to do, how, edge cases. Detail *is* the value here.
- **You, triaging inbound** → what is this, does it need me, what's the catch, what's the deadline.
- **Reader of an article / essay** → wants to *be persuaded or informed*, not to act. They give you their attention, not a decision. What matters: a clear thesis they can restate, why it matters to them, and the few insights worth remembering. There is no "ask," no owner, no deadline — do not invent them.

If the document names or implies its audience, use that. If two readers are plausible and they'd want different things, **ask one question** rather than averaging — averaging produces a document that serves neither.

## Step 3 — derive "what matters" (3–6 items)

For the genre+reader, list the few things this reader would be *wrong to miss*. Generic high-consequence categories to check for, in rough priority for a decision-maker:

1. **The recommendation / bottom line** — what should happen.
2. **The ask / decision** — what the reader must do, by when.
3. **Money** — cost, budget impact, ROI.
4. **Risk** — what could go wrong, severity, likelihood.
5. **Timeline / deadline** — when it matters.
6. **Owner / accountability** — who's responsible.
7. **Status / what changed** — current state vs. expected.
8. **Why / rationale** — only as much as needed to trust the above.

This is a checklist for *what to look for and whether it's present* — not a template to impose. A research memo's "what matters" leads with findings and confidence, not cost. Let the genre+reader rank the list, and treat any high-consequence category that's **absent** from the document as a completeness gap (audit lens 4).

**For an article / essay this list does not apply.** A thought-leadership piece is judged on a different axis entirely — thesis, hook, through-line, memorable insights, honest balance — not on cost/owner/deadline. Switch to the article lenses in `../prompts/audit.md` and the editorial path in `../prompts/render.md`. Do **not** treat the absence of an "ask" or a "deadline" as a gap; for this genre their absence is correct.

## The discipline

Author-importance ≠ reader-importance. The author ranks by effort and chronology; the reader ranks by consequence to them. Every time you're unsure whether something leads, ask: "if the reader missed only this, would they make a worse decision?" If yes, it leads. If no, it recedes.
