# EY Brand Guidelines

Extracted from official EY Global Widescreen Presentation Templates v2.1

---

## Color Palette

### Core Brand Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **EY Yellow** | `#FFE600` | 255, 230, 0 | Primary brand accent, highlights, hyperlinks (dark theme) |
| **EY Black** | `#1A1A24` | 26, 26, 36 | Dark theme background, text on light |
| **EY Dark Gray** | `#2E2E38` | 46, 46, 56 | Secondary text, borders, light theme accents |
| **White** | `#FFFFFF` | 255, 255, 255 | Light theme background, text on dark |

### Premium Dark Theme Colors

For editorial-quality presentations, use this refined dark palette:

| Name | Hex | Usage |
|------|-----|-------|
| **Premium Black** | `#0D0D0F` | Primary background (softer than pure black) |
| **Card Background** | `rgba(255,255,255,0.03)` | Subtle card/panel backgrounds |
| **Card Border** | `rgba(255,255,255,0.08)` | Subtle borders |
| **Text Primary** | `#FFFFFF` | Headlines, primary text |
| **Text Secondary** | `rgba(255,255,255,0.7)` | Body text, descriptions |
| **Text Muted** | `rgba(255,255,255,0.4)` | Labels, footnotes |
| **Highlight** | `#FFE600` | Key term emphasis in paragraphs |

### Spectrum Accent Colors

Use sparingly for data visualization and emphasis. **Do not apply to headlines or body text.**

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Green** | `#2DB757` | 45, 183, 87 | Positive, growth, success |
| **Teal** | `#27ACAA` | 39, 172, 170 | Neutral accent, secondary data |
| **Blue** | `#188CE5` | 24, 140, 229 | Information, links (light theme: `#0F69AE`) |
| **Purple** | `#750E5C` | 117, 14, 92 | Tertiary accent |
| **Red** | `#FF4136` | 255, 65, 54 | Negative, decline, warning |
| **Orange** | `#FF6D00` | 255, 109, 0 | Caution, highlight |

### Icon/Badge Colors (for system logos)

| System | Gradient |
|--------|----------|
| ServiceNow | `linear-gradient(135deg, #62B359 0%, #4A9E4A 100%)` |
| Workday | `linear-gradient(135deg, #F68B1F 0%, #E67E00 100%)` |
| SAP | `linear-gradient(135deg, #008FD3 0%, #0070A0 100%)` |
| Azure/Microsoft | `linear-gradient(135deg, #00A4EF 0%, #0078D4 100%)` |
| AI/Search | `linear-gradient(135deg, #00B294 0%, #008272 100%)` |

### Color Usage Rules

1. **EY Yellow is for highlighting, not decoration** — Use it to draw attention to key insights
2. **Avoid colorful backgrounds on content-heavy slides** — Use solid dark (#0D0D0F) or white (#FFFFFF)
3. **Do not apply spectrum colors to titles, headlines, or body text** — Keep text white (dark theme) or black (light theme)
4. **Spectrum backgrounds are for section dividers and title slides only**
5. **Premium mode: Use consistent dark backgrounds throughout** — No white slides mixed with dark slides

---

## Typography

### Primary Fonts

| Role | Font | Weight | Fallback |
|------|------|--------|----------|
| **Headlines** | EYInterstate | Regular | Inter, Arial, Helvetica, sans-serif |
| **Body** | EYInterstate | Light | Inter, Arial, Helvetica, sans-serif |

### Standard Size Guidelines

| Element | Dark Theme | Light Theme |
|---------|------------|-------------|
| Slide Title | 44pt | 44pt |
| Section Header | 60pt+ | 60pt+ |
| Headline | 28-36pt | 28-36pt |
| Subheadline | 24pt | 24pt |
| Body Text | 20pt | 20pt |
| Bullet Points | 20pt | 20pt |
| Footnotes | 12pt | 12pt |

### Premium Mode Size Guidelines (HTML/PDF)

| Element | Size | Weight | Notes |
|---------|------|--------|-------|
| Hero Headlines | 96-120px | 900 | Title slides, big statements |
| Slide Headlines | 48-54px | 800 | Primary slide titles |
| Card Titles | 24-28px | 700 | Card/panel headers |
| Section Labels | 12-13px | 600-700 | Uppercase, letter-spacing: 2-3px |
| Body Text | 18-20px | 400-500 | **Never smaller than 17px** |
| Card Descriptions | 17-19px | 400 | Supporting text in cards |
| List Items | 17-18px | 400 | Bullet points, phase items |
| Footnotes | 12-13px | 400 | Footer text, citations |

### Font Installation Note

EYInterstate is a proprietary EY font. If not installed, PowerPoint will substitute with Arial. For HTML-to-PDF workflow, use Inter (Google Fonts) as the primary fallback:

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap');

font-family: 'Inter', -apple-system, sans-serif;
```

---

## Yellow Highlighting System

**Use yellow highlights to emphasize key terms within paragraph text.**

### CSS Implementation

```css
.hl { 
  color: #FFE600; 
  font-weight: 600; 
}
```

### HTML Usage

```html
<p><span class="hl">Phase 1</span> delivered <span class="hl">11 productivity agents</span>. 
<span class="hl">Phase 2</span> transforms this into <span class="hl">enterprise-grade capability</span>.</p>
```

### What to Highlight

| Category | Examples |
|----------|----------|
| Phase/version references | "Phase 1", "Phase 2", "v2.0" |
| Metrics and numbers | "11 agents", "50+ engagements", "$1M" |
| Technical terms | "Azure AI Foundry", "Microsoft Agent Framework", "RAG patterns" |
| System/product names | "ServiceNow", "Workday", "SAP", "Sinequa" |
| Key concepts | "enterprise-grade", "multi-agent orchestration", "production-ready" |
| Action/impact words | "transforms", "delivers", "scales", "eliminates" |
| Time references | "6-month engagement", "Months 1-2" |

### Highlighting Rules

1. **3-5 highlights per paragraph maximum** — More dilutes impact
2. **Highlight phrases, not sentences** — Keep highlights to 1-4 words
3. **Be consistent** — If "Phase 1" is highlighted once, highlight it everywhere
4. **Don't highlight generic words** — "the", "and", "with", "for" should never be highlighted
5. **Headlines don't need highlights** — They're already prominent

---

## Logo & Footer

### Official Logo Assets

The following official EY logo files are available in `assets/brand/`:

| File | Usage | Description |
|------|-------|-------------|
| `ey-logo-dark.png` | **Dark theme slides** | Yellow beam + white "EY" text on transparent background |
| `ey-logo-light.png` | **Light theme slides** | Yellow beam + dark "EY" text on transparent background |
| `ey-logo-light-small.png` | **Small placements** | Compact version for tight spaces on light backgrounds |
| `ey-beam.png` | **Decorative accents** | Yellow beam only, for creative layouts |

### Logo Implementation

**ALWAYS use the official logo images.** Never recreate the EY logo as text.

#### HTML/PDF Implementation

```html
<!-- Dark theme (premium mode) -->
<img src="ey-logo-dark.png" alt="EY" class="ey-logo" />

<!-- Light theme -->
<img src="ey-logo-light.png" alt="EY" class="ey-logo" />
```

```css
.ey-logo {
  height: 40px;        /* Adjust as needed */
  width: auto;
  object-fit: contain;
}

/* Header position */
.header .ey-logo {
  height: 32px;
}

/* Footer position */
.footer .ey-logo {
  height: 24px;
}
```

#### Base64 Embedding (for standalone HTML)

When creating single-file HTML slides, embed the logo as base64 to ensure it renders in PDFs:

```python
import base64

with open('ey-logo-dark.png', 'rb') as f:
    logo_b64 = base64.b64encode(f.read()).decode()
    
# Use in HTML:
# <img src="data:image/png;base64,{logo_b64}" alt="EY" class="ey-logo" />
```

### Logo Placement
- **Position:** Top-right or bottom-right corner
- **Minimum clear space:** Equal to height of "EY" on all sides
- **Tagline:** "Shape the future with confidence" (title slides only)

### Footer Elements
- Slide number (bottom-left)
- Date (left of slide number)
- Custom footer text (center-left)
- EY logo (bottom-right)

### Brand Tagline
"The better the question. The better the answer. The better the world works."
Used on title slides with spectrum frame.

---

## Template Files

Both templates are stored in `assets/templates/`:

- `ey-dark.pptx` — Dark theme (77 slides, spectrum backgrounds)
- `ey-light.potx` — Light theme (67 slides, white backgrounds)

### Template Structure

**Slides 1-4:** Guidance slides (remove before distribution)
**Slides 5+:** Usable layouts

### Key Layout Types

| Layout | Purpose | Background |
|--------|---------|------------|
| Spectrum Title (1-4) | Cover slides with frame | Spectrum gradient |
| Yellow Frame Title | Image background with frame | Photo + gradient overlay |
| Section Header (1-6) | Chapter dividers | Spectrum gradient |
| Agenda | Meeting structure | Solid or spectrum |
| Content (2-col, 3-col) | Body content | Solid dark/white |
| Title Only | Flexible content area | Solid or spectrum |
| Comparison | Side-by-side | Solid |
| Timeline | Process flow | Solid |
| Quote | Statement emphasis | Solid or spectrum |
| Closing | End slides | Spectrum |

---

## CSS Variables for HTML-to-PDF (Premium Mode)

When creating custom slides via HTML, use these variables:

```css
:root {
  /* === EY Brand Colors === */
  --ey-yellow: #FFE600;
  --ey-black: #1A1A24;
  --ey-dark-gray: #2E2E38;
  --ey-white: #FFFFFF;
  
  /* === Premium Dark Theme === */
  --premium-bg: #0D0D0F;
  --card-bg: rgba(255,255,255,0.03);
  --card-border: rgba(255,255,255,0.08);
  --card-border-accent: rgba(255,230,0,0.3);
  --text-primary: #FFFFFF;
  --text-secondary: rgba(255,255,255,0.7);
  --text-muted: rgba(255,255,255,0.4);
  --highlight: #FFE600;
  
  /* === Spectrum Accents === */
  --ey-green: #2DB757;
  --ey-teal: #27ACAA;
  --ey-blue: #188CE5;
  --ey-blue-light: #0F69AE;
  --ey-purple: #750E5C;
  --ey-red: #FF4136;
  --ey-orange: #FF6D00;
  
  /* === Typography === */
  --font-primary: 'Inter', -apple-system, sans-serif;
  --font-weight-light: 300;
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --font-weight-extrabold: 800;
  --font-weight-black: 900;
  
  /* === Premium Typography Sizes === */
  --size-hero: 96px;
  --size-headline: 52px;
  --size-card-title: 26px;
  --size-label: 12px;
  --size-body: 19px;
  --size-body-min: 17px;
  --size-footnote: 12px;
  
  /* === Spacing === */
  --slide-padding: 80px 100px;
  --card-padding: 36px;
  --card-radius: 16px;
  --gutter: 32px;
}

/* === Highlight Class === */
.hl { 
  color: var(--highlight); 
  font-weight: var(--font-weight-semibold); 
}
```

---

## Premium Slide Base Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Slide Title</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap');
    
    * { margin: 0; padding: 0; box-sizing: border-box; }
    
    body {
      width: 1920px;
      height: 1080px;
      font-family: 'Inter', -apple-system, sans-serif;
      background: #0D0D0F;
      color: #FFFFFF;
      overflow: hidden;
    }
    
    .hl { color: #FFE600; font-weight: 600; }
    
    .content {
      height: 100%;
      padding: 80px 100px;
      display: flex;
      flex-direction: column;
    }
    
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 48px;
    }
    
    .slide-label {
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 3px;
      text-transform: uppercase;
      color: rgba(255,255,255,0.4);
    }
    
    .ey-logo {
      height: 40px;
      width: auto;
    }
    
    h1 {
      font-size: 52px;
      font-weight: 800;
      line-height: 1.1;
      letter-spacing: -2px;
      margin-bottom: 48px;
    }
    
    .footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 12px;
      color: rgba(255,255,255,0.3);
      margin-top: auto;
      padding-top: 32px;
    }
    
    .footer .ey-logo {
      height: 24px;
    }
  </style>
</head>
<body>
  <div class="content">
    <div class="header">
      <span class="slide-label">Section Label</span>
      <!-- ALWAYS use official EY logo image, never text -->
      <img src="ey-logo-dark.png" alt="EY" class="ey-logo" />
    </div>
    
    <h1>Headline with <span class="hl">Key Term</span> Highlighted</h1>
    
    <!-- Slide content here -->
    
    <div class="footer">
      <span>EY | Confidential</span>
      <span>1</span>
    </div>
  </div>
</body>
</html>
```

**IMPORTANT:** For PDF generation, embed the logo as base64 using the script below. Load the logo from `assets/brand/ey-logo-dark.png` (dark theme) or `assets/brand/ey-logo-light.png` (light theme).

---

## Design Principles (from EY Guidelines)

1. **Simple and confident** — Project gravitas through restraint
2. **Yellow highlights, not decoration** — Use EY Yellow to emphasize, not beautify
3. **Solid backgrounds for dense content** — Reserve spectrum for titles and dividers
4. **Clarity over creativity** — Sophistication comes from precision, not complexity
5. **Pacing matters** — Balance expressive moments with clean, focused content slides
6. **Consistent dark theme in premium mode** — No jarring white slides mixed with dark
7. **Readable body text** — Never smaller than 17px in premium presentations
8. **Strategic highlighting** — 3-5 yellow highlights per paragraph maximum
