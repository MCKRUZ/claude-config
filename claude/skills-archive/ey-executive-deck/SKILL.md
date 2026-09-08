---
name: ey-executive-deck
description: Create compelling executive presentations for EY Managing Directors. Use when asked to create PowerPoint decks, client proposals, strategy recommendations, or executive presentations. Triggers on requests for slides, decks, presentations, pitches, or board materials. Emphasizes narrative clarity and visual excellence for C-suite decision-makers. Integrates EY brand guidelines with flexible design that can use or transcend template layouts.
---

# EY Executive Deck Creator

Create decision-driving presentations for C-suite audiences. Story first, design second—but both must be exceptional.

## Core Philosophy

**Every slide must pass two tests:**
1. **The "So What?" Test** — Does this slide drive toward a decision? What action should the audience take?
2. **The "Glance Test"** — Can the key message be understood in 3 seconds?

## Workflow Overview

1. **Discover** — Ask questions to understand the narrative (never skip)
2. **Structure** — Build the story arc before any slides
3. **Design** — Create visually compelling slides that reinforce the message
4. **Validate** — Review every slide against quality criteria

---

## Phase 1: Narrative Discovery

**CRITICAL: Never create slides without first understanding the story.**

Ask these questions in a conversational flow. Don't overwhelm—start with essentials and dig deeper as needed.

### Essential Questions (Always Ask)

1. **The Decision**: "What specific decision or approval are you seeking?"
2. **The Audience**: "Who will be in the room, and what do they care about most?"
3. **The Stakes**: "What happens if they say yes? What if they say no?"
4. **The Resistance**: "What objections or concerns do you anticipate?"

### Deepening Questions (As Needed)

5. **The Context**: "What do they already know? What's the backstory?"
6. **The Evidence**: "What proof points or data support your recommendation?"
7. **The Competition**: "Are there alternative approaches they might prefer?"
8. **The Timeline**: "What urgency exists? When must they decide?"

### Synthesis Checkpoint

Before proceeding, confirm the narrative by stating back:
- "Here's what I understand: You're asking [AUDIENCE] to [DECISION] because [REASONING]. The main concerns will be [OBJECTIONS], which we'll address with [EVIDENCE]. Is that right?"

---

## Phase 2: Story Structure

Use one of these proven narrative frameworks. See `references/narrative-framework.md` for detailed guidance.

### Framework Selection

| Situation | Framework |
|-----------|-----------|
| Recommending a new initiative | **Situation-Complication-Resolution (SCR)** |
| Presenting options for decision | **MECE Options with Recommendation** |
| Responding to a problem | **Problem-Cause-Solution** |
| Persuading skeptical audience | **Why-What-How-What If** |

### Slide Architecture (10-15 slides)

```
1. Title Slide — Clear statement of purpose
2. Executive Summary — The answer upfront (1 slide)
3. Situation/Context — Where we are (1-2 slides)
4. Challenge/Opportunity — Why action is needed (1-2 slides)
5. Recommendation — What we propose (1-2 slides)
6. Supporting Evidence — Proof points (3-4 slides)
7. Implementation/Next Steps — How we execute (1-2 slides)
8. Ask/Decision Required — Clear call to action (1 slide)
9. Appendix — Backup detail (as needed)
```

**Rule: Answer First.** Executives want the recommendation on slide 2, not slide 15. Support it afterward.

---

## Phase 3: Slide Design

### Design Modes

**Ask the user which mode they prefer, or infer from context:**

#### Standard Mode (Default)
- Template-based PPTX using EY templates
- Clean, professional, brand-compliant
- Good for internal presentations, routine updates

#### Premium Mode (When Requested)
- HTML-to-PDF workflow for maximum design control
- Editorial magazine quality with dramatic layouts
- Use when user asks for "wow factor," "premium," "impressive," or "high-design"
- **Creative enhancements**: Asymmetric layouts, texture, animation, AI-generated visuals
- See **Premium Design System** section below
- See `references/creative-enhancements.md` for advanced techniques

### Brand Requirements

**Read `assets/brand/ey-brand.md` for EY colors and typography.** Brand consistency is non-negotiable.

Template layouts in `assets/templates/` are available but optional—use them when they serve the narrative, transcend them when they don't.

### Design Principles

Follow these rules for every slide. See `references/design-principles.md` for examples and `references/creative-design-system.md` for advanced techniques.

#### 1. One Idea Per Slide
- If you need "and" in your headline, split the slide
- The headline IS the takeaway (not a topic label)

#### 2. Headlines That Assert
❌ "Q3 Financial Results"  
✅ "Q3 Revenue Exceeded Target by 12%, Driven by Enterprise Growth"

#### 3. Visual Hierarchy
- **Primary**: Headline (largest, boldest)
- **Secondary**: Key data or visual
- **Tertiary**: Supporting detail
- Create clear visual flow from top-left to bottom-right

#### 4. Strategic White Space
- Don't fill every inch—breathing room signals confidence
- Margins: minimum 0.5" on all sides
- Group related elements, separate unrelated ones

#### 5. Data Visualization
- Chart type must match the message (see `references/design-principles.md`)
- Highlight the insight, not just the data
- Remove chartjunk: gridlines, unnecessary legends, 3D effects

#### 6. Text Discipline
- Body text: 18pt minimum (20pt preferred for premium)
- Bullets: 3-5 per slide maximum
- If you're writing paragraphs, you're doing it wrong

---

## Premium Design System

**Use when user requests high-impact, editorial-quality presentations.**

### Trigger Phrases
- "Make it impressive" / "wow factor" / "premium"
- "Not template-y" / "design-forward"
- "Client pitch" / "board presentation" / "executive audience"

### Technical Approach

1. **HTML-to-PDF Workflow**
   - Create individual HTML files per slide (1920x1080 canvas)
   - Use Playwright to render to PDF
   - Merge with pdfunite for final deck

2. **Color System (Dark Theme)**
   ```css
   --background: #0D0D0F;        /* Near-black, not pure black */
   --text-primary: #FFFFFF;
   --text-secondary: rgba(255,255,255,0.7);
   --text-muted: rgba(255,255,255,0.4);
   --accent: #FFE600;            /* EY Yellow */
   --highlight: #FFE600;         /* For key term emphasis */
   ```

3. **No White Backgrounds in Premium Mode**
   - Use consistent dark theme throughout
   - Avoid jarring contrast between slides
   - Reserve yellow for accents, not backgrounds (except CTAs)

### Typography Scale (Premium)

| Element | Size | Weight |
|---------|------|--------|
| Hero Headlines | 96-120px | 900 (Black) |
| Slide Headlines | 48-54px | 800 (ExtraBold) |
| Section Labels | 12-13px | 600-700, uppercase, letter-spacing: 2-3px |
| Body Text | 18-20px | 400-500 |
| Card Descriptions | 17-19px | 400 |
| Supporting Text | 16-18px | 400 |
| Footnotes | 12-13px | 400 |

**Key Rule: Body text should never be smaller than 17px in premium decks.**

### Yellow Highlighting System

**Use yellow highlights to emphasize key terms in paragraph text.**

```html
<span class="hl">key term</span>
```

```css
.hl { 
  color: #FFE600; 
  font-weight: 600; 
}
```

#### What to Highlight
- **Phase references**: "Phase 1", "Phase 2"
- **Metrics and numbers**: "11 agents", "50+ engagements", "6-month"
- **Technical terms**: "Azure AI Foundry", "Microsoft Agent Framework"
- **System names**: "ServiceNow", "Workday", "SAP"
- **Key concepts**: "enterprise-grade", "multi-agent orchestration"
- **Action words**: "transforms", "delivers", "production-ready"

#### What NOT to Highlight
- Every noun in a sentence
- Generic words like "the", "and", "with"
- More than 4-5 terms per paragraph

**Example:**
```html
<p><span class="hl">Phase 1</span> delivered <span class="hl">11 productivity agents</span>—2 in production, 9 production-ready. <span class="hl">Phase 2</span> transforms this foundation into <span class="hl">enterprise-grade capability</span> using <span class="hl">Azure AI Foundry</span> and <span class="hl">Microsoft Agent Framework</span>.</p>
```

### Premium Layout Patterns

#### Split Panel
- 50/50 or 45/55 split
- One side: bold statement or big number
- Other side: supporting content or visual

#### Card Grid
- 2-4 cards per row
- Consistent padding (36-48px)
- Subtle borders: `1px solid rgba(255,255,255,0.08)`
- Hover states for interactivity cues

#### Diagonal Accents
- Yellow diagonal bars for visual interest
- Use CSS clip-path for dramatic splits
- Creates editorial magazine feel

#### Big Number + Context
- Oversized metrics (96-200px)
- Supporting label below
- Yellow for emphasis numbers

### Creative Enhancement (Premium Mode)

**For premium presentations, go beyond templates.** Read `references/creative-enhancements.md` for advanced techniques:

- **Layout**: Asymmetric splits, diagonal accents, overlapping elements, edge-bleeding
- **Typography**: Extreme size contrast, weight pairing, letterspacing as texture
- **Atmosphere**: Gradient meshes, noise textures, geometric patterns
- **Motion**: Staggered reveals, hover states, animated accents

**Key principle:** EY brand defines the palette and typography—creativity lives in composition, texture, and spatial drama.

### AI-Generated Visual Assets

Use Hugging Face MCP services to create custom imagery for premium presentations:

| MCP Service | Use For |
|-------------|---------|
| `Hugging Face:dynamic_space` → `mcp-tools/FLUX.1-Krea-dev` | Abstract hero images, dramatic atmospheres |
| `Hugging Face:dynamic_space` → `mcp-tools/Qwen-Image` | Clean conceptual illustrations |
| `Hugging Face:dynamic_space` → `not-lain/background-removal` | Isolating client logos |

**Prompt pattern for EY-appropriate imagery:**
```
"Abstract [concept], dark background #0D0D0F, subtle yellow accent highlights #FFE600, 
minimal, sophisticated, editorial quality, no text, premium corporate aesthetic"
```

**Integration rules:**
1. Reduce opacity to 15-30% for backgrounds
2. Add gradient overlay for text readability
3. Match color temperature to EY palette
4. Prefer abstract over literal imagery
5. Test with text overlay before committing

### Premium Build Script

```python
# build_deck.py
from playwright.sync_api import sync_playwright
import glob, os, base64, re

# Load official EY logo and convert to base64
SKILL_PATH = '/mnt/skills/user/ey-executive-deck'
with open(f'{SKILL_PATH}/assets/brand/ey-logo-dark.png', 'rb') as f:
    LOGO_B64 = base64.b64encode(f.read()).decode()

def embed_logo(html_content):
    """Replace logo src with base64 embedded version"""
    # Replace file path with base64 data URI
    html_content = re.sub(
        r'src=["\'](?:\.\/)?ey-logo-dark\.png["\']',
        f'src="data:image/png;base64,{LOGO_B64}"',
        html_content
    )
    return html_content

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={'width': 1920, 'height': 1080})
    
    for html_file in sorted(glob.glob('slide*.html')):
        pdf_file = html_file.replace('.html', '.pdf')
        
        # Read and embed logo
        with open(html_file, 'r') as f:
            html_content = embed_logo(f.read())
        
        # Write temp file with embedded logo
        temp_file = f'_temp_{html_file}'
        with open(temp_file, 'w') as f:
            f.write(html_content)
        
        page.goto(f'file://{os.path.abspath(temp_file)}')
        page.pdf(path=pdf_file, width='1920px', height='1080px', 
                 print_background=True, scale=1)
        os.remove(temp_file)
        print(f'Converting {html_file} -> {pdf_file}')
    
    browser.close()
```

Merge with: `pdfunite slide*.pdf final-deck.pdf`

### Creative Design System

**For advanced visual techniques, read `references/creative-design-system.md`.**

This reference provides:
- Advanced typography techniques (weight contrast, letter-spacing, mixed hierarchy)
- Layout patterns that break the grid (asymmetry, diagonal flow, overlapping elements)
- Atmospheric backgrounds (gradient meshes, noise textures, ambient glows)
- Motion and animation (staggered reveals, hover states)
- Premium card designs (glass cards, accent borders, spotlight effects)
- Ready-to-use HTML templates for common slide types

Use these techniques to elevate presentations beyond standard templates while staying within EY brand constraints.

### AI-Generated Custom Imagery (MCP)

Use Hugging Face MCP tools to generate custom visuals for hero slides, section dividers, and abstract backgrounds.

**Available tools:**
| Tool | Best For |
|------|----------|
| `Hugging Face:dynamic_space` → `mcp-tools/FLUX.1-Krea-dev` | Abstract backgrounds, atmospheric visuals |
| `Hugging Face:dynamic_space` → `mcp-tools/Qwen-Image` | High-quality images with text-friendly composition |
| `Hugging Face:dynamic_space` → `mcp-tools/FLUX.1-Kontext-Dev` | Editing/transforming existing images |

**EY-compliant prompt pattern:**
```
Abstract [concept] visualization, dark background #0D0D0F, 
subtle golden yellow #FFE600 accent highlights, professional 
corporate aesthetic, clean lines, minimal, sophisticated, 
no faces, no text, 8k quality
```

**Post-processing:** Always add a dark gradient overlay to ensure text readability:
```css
.hero-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to bottom, rgba(13,13,15,0.7), rgba(13,13,15,0.95));
}
```

See `references/creative-design-system.md` for detailed prompts and integration patterns.

### Official Logo Assets

**CRITICAL: Always use the official EY logo images from `assets/brand/`. Never recreate the logo as text.**

| File | Theme | Usage |
|------|-------|-------|
| `ey-logo-dark.png` | Dark | Yellow beam + white text (for premium dark slides) |
| `ey-logo-light.png` | Light | Yellow beam + dark text (for light backgrounds) |
| `ey-beam.png` | Any | Yellow beam only (decorative accents) |

---

## Phase 4: Technical Execution

### Using the PPTX Skill

This skill builds on the core `pptx` skill. Read `/mnt/skills/public/pptx/SKILL.md` for technical implementation.

**Three paths:**

#### Path A: Template-Based (Standard presentations)
1. Use EY template from `assets/templates/`
2. Follow the template-based workflow in pptx skill
3. Extract inventory, duplicate slides, replace content

#### Path B: HTML-to-PPTX (Custom layouts, still PPTX output)
1. Use html2pptx workflow from pptx skill
2. Apply EY brand colors/fonts from `assets/brand/ey-brand.md`
3. Create custom layouts that serve the narrative

#### Path C: HTML-to-PDF (Premium presentations)
1. Create HTML slides with premium design system
2. Render to PDF via Playwright
3. Maximum design control, editorial quality
4. Use when "wow factor" is required

### Visual Validation Checklist

Before delivering, verify each slide:
- [ ] Headline asserts a takeaway (not a topic label)
- [ ] One idea only—no compound messages
- [ ] Text is readable at presentation distance (18pt+ body, 17px+ for premium)
- [ ] Brand colors applied correctly
- [ ] Visual hierarchy is clear
- [ ] White space is intentional
- [ ] Charts highlight the insight
- [ ] **Premium only:** Key terms highlighted in yellow
- [ ] **Premium only:** Consistent dark background throughout

---

## Quick Reference: Slide Types

| Slide Type | Purpose | Key Elements |
|------------|---------|--------------|
| Title | Set context | Title, subtitle, date, presenter |
| Executive Summary | Answer upfront | 3-5 bullet synthesis of recommendation |
| Context/Situation | Establish baseline | Current state, relevant background |
| Challenge | Create urgency | Problem statement, impact, stakes |
| Recommendation | Propose solution | Clear action statement, key benefits |
| Evidence | Build credibility | Data, case studies, proof points |
| Comparison | Enable choice | Side-by-side options, clear criteria |
| Timeline/Roadmap | Show path forward | Phases, milestones, owners |
| Ask/CTA | Drive decision | Specific request, next steps |

---

## Common Pitfalls to Avoid

1. **Burying the lead** — Put the answer on slide 2, not the appendix
2. **Topic headlines** — "Market Analysis" tells them nothing; assert the finding
3. **Wall of text** — If they can read it themselves, why are you presenting?
4. **Decoration over information** — Every visual element must earn its place
5. **Missing the ask** — End with a clear, specific request for action
6. **Inconsistent backgrounds** — In premium mode, stick to dark theme throughout
7. **Text too small** — Body text under 17px is unreadable at presentation distance
8. **Over-highlighting** — Yellow highlights lose impact if overused
9. **Generic AI aesthetics** — Avoid purple gradients, centered layouts, stock imagery, predictable compositions
10. **Same layout repeated** — Vary composition across slides; each should feel intentionally designed
