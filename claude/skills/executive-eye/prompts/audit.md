# Audit — the scorecard

The audit is the heart of the skill. It is a **diagnosis**, delivered inline in chat, that tells the user whether their document works for its reader and what the single highest-leverage fix is. It never rewrites.

## Before scoring

You have already established (from SKILL.md step 1): what the document is, who reads it, and what matters most for that reader. The audit measures the document *against that reader* — not against generic "good writing."

## The five lenses

Score each lens. For each, give a one-line judgment and **cite the location** of the evidence. Vague findings ("could be tighter") are useless — point at the exact bullet, paragraph, or heading.

### 1. Lead — is the most important thing first and visible?
The reader's eye lands on the top of the first screen. Is the single most consequential point *there*? Or is it in the conclusion, the last bullet, paragraph four, an appendix?
- **Pass:** a reader who stops after the first screen still leaves with the right takeaway.
- **Fail:** "The recommendation to pause the rollout is the last sentence of §3."

### 2. Ask — is what the reader must do explicit?
Most documents exist to produce a decision or an action. Is it stated plainly — what, by whom, by when — or must the reader infer it?
- **Pass:** "Decision needed: approve $40k by Friday" appears as such.
- **Fail:** "The ask is implied across §2 and §5 but never stated as a decision."

### 3. Weight — does prominence match consequence?
Critical and trivial content should not look the same. A one-line risk that could sink the project shouldn't sit in a sub-bullet next to a note about meeting logistics.
- **Fail:** "The data-loss risk and the catering update are both plain bullets under the same heading."

### 4. Completeness — are the reader's first questions answered?
For this reader and genre, what do they ask immediately? (Cost, risk, owner, deadline, current status, the recommendation and why, what changed, what's blocked.) Flag the ones with **no answer in the document**. This surfaces gaps — it does not fill them.
- **Fail:** "No owner and no target date anywhere; a status report's reader asks both first."

### 5. Noise — what dilutes the signal?
Content that doesn't serve *this* reader. Background the reader already knows, throat-clearing, hedging that hides the point, detail that belongs in an appendix.
- **Fail:** "§1 spends three paragraphs on history the board already lived through."

## Article / essay mode

When the genre is an article, essay, or thought-leadership piece (blog, Substack, op-ed), the decision-doc lenses misfire — an essay has no "ask," no owner, no deadline, and its caveats are content, not gaps. **Do not score it on the five lenses above.** Use these instead, and never report a missing decision/owner/deadline as a finding:

### 1. Hook — does the opening earn the next paragraph?
The first lines decide whether a busy reader keeps going. Is there a sharp entry — a tension, a claim, a vivid stake — or does it open with throat-clearing and background?
- **Fail:** "Opens with three sentences of 'AI is changing everything' before any real claim."

### 2. Thesis — can a skimming reader restate the point in one sentence?
A thought-leadership piece lives or dies on one idea. Is it stated clearly and early, and does the title deliver on it?
- **Fail:** "The actual thesis ('govern at the gateway, not the model') doesn't surface until §2; the reader skimming the top wouldn't catch it."

### 3. Through-line — does the argument build, or just accumulate?
Sections should advance the case, each earning the next. Flag digressions, repetition, and ordering that breaks the logic.
- **Fail:** "The identity section interrupts the GA/preview argument and breaks the build."

### 4. Emphasis — are the best lines surfaced or buried?
Essays have memorable, quotable insights and key stats. Are they given weight (pull-quote, bold, their own line) or lost mid-paragraph where a skimmer misses them?
- **Fail:** "'The trust boundary moved' is the strongest line and it's the last sentence — nothing earlier signals it."

### 5. Balance & honesty (for analytical/technical essays) — is the claim/caveat ratio credible?
Persuasive writing that hides its limits reads as marketing. Does the piece earn trust by naming what's uncertain, preview, or contested?
- **Note:** this is praise when present. "Caveats are stated plainly throughout — strengthens credibility."

Plus **Noise** (lens 5 above) applies unchanged. End with the same verdict shape, reframed: *would a busy executive reader come away persuaded and remember the point — and what's the one change that would most improve the read.*

## Output format

Keep it scannable. Something like:

```
EXECUTIVE EYE — audit of <doc name>
This is: <one line>. Reader: <one line>. What matters: <3–6 items>.

▸ Lead       <pass/weak/fail> — <finding + location>
▸ Ask        <pass/weak/fail> — <finding + location>
▸ Weight     <pass/weak/fail> — <finding + location>
▸ Complete   <pass/weak/fail> — <finding + location>
▸ Noise      <pass/weak/fail> — <finding + location>

Verdict: <can the reader act correctly from the first screen? yes/no>
Highest-leverage fix: <the one change that matters most>
```

Then offer Transform / Summarize / Render (SKILL.md step 3).

## Tone

Direct and specific, like a sharp editor — not a rubric robot. If the document is already good, say so plainly and don't manufacture findings. A clean audit ("this works for its reader; only nit is X") is a valid and valuable result.
