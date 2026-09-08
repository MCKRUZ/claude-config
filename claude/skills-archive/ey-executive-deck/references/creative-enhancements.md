# Creative Enhancements for Premium EY Presentations

Push creative boundaries while respecting EY brand guidelines. This guide elevates HTML/PDF presentations beyond generic "AI-generated" aesthetics into editorial-quality executive materials.

---

## Design Philosophy

**Principle: Bold within boundaries.** EY brand provides the palette and typography—creativity lives in composition, texture, motion, and atmosphere.

### What's Fixed (Brand Non-Negotiables)
- Color palette: EY Yellow (#FFE600), Premium Black (#0D0D0F), grays, spectrum accents
- Typography: Inter (or EYInterstate) family only
- Logo: Official PNG assets only, positioned top-right or bottom-right
- Footer: Slide numbers, confidentiality notice, EY branding

### Where Creativity Lives
- **Layout composition**: Asymmetry, overlap, diagonal flow, grid-breaking
- **Spatial drama**: Unexpected white space, edge-bleeding elements, tension
- **Texture and depth**: Gradients, noise, subtle patterns, layered transparencies
- **Motion and reveal**: CSS animations, staggered entrances, micro-interactions
- **Typography expression**: Weight contrast, size drama, letterspacing as design element
- **Generated imagery**: AI-created abstract visuals, textures, and backgrounds

---

## Layout Patterns (Beyond the Grid)

### Asymmetric Tension
Break the predictable 50/50 split. Create visual interest through imbalance.

```css
.asymmetric-layout {
  display: grid;
  grid-template-columns: 1fr 2fr; /* 33/66 split */
  gap: 60px;
}

.asymmetric-reverse {
  grid-template-columns: 2fr 1fr; /* 66/33 split */
}

/* Dramatic: narrow sidebar with massive content */
.dramatic-split {
  grid-template-columns: 280px 1fr;
}
```

### Diagonal Energy
Use clip-path and transforms to break rectangular monotony.

```css
.diagonal-accent {
  position: absolute;
  width: 400px;
  height: 100%;
  background: linear-gradient(135deg, #FFE600 0%, rgba(255,230,0,0.3) 100%);
  clip-path: polygon(0 0, 100% 0, 70% 100%, 0 100%);
  left: -100px;
  opacity: 0.15;
}

.diagonal-divider {
  width: 100%;
  height: 4px;
  background: #FFE600;
  transform: rotate(-2deg);
  margin: 48px 0;
}
```

### Overlap and Layering
Create depth by breaking element boundaries.

```css
.overlap-container {
  position: relative;
}

.overlap-card {
  position: relative;
  z-index: 2;
  margin-top: -40px; /* Bleeds into section above */
  margin-left: 60px;
}

.floating-stat {
  position: absolute;
  top: -30px;
  right: 40px;
  background: #FFE600;
  color: #0D0D0F;
  padding: 20px 32px;
  font-size: 48px;
  font-weight: 800;
}
```

### Edge Bleeding
Let elements escape the container for dramatic effect.

```css
.bleed-left {
  margin-left: -100px;
  padding-left: 100px;
}

.bleed-right {
  margin-right: -100px;
  width: calc(100% + 100px);
}

.full-bleed-image {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.15;
  z-index: 0;
}
```

---

## Typography as Design

### Size Drama
Create hierarchy through extreme contrast, not just incremental steps.

```css
/* Hero numbers: oversized for impact */
.hero-stat {
  font-size: 180px;
  font-weight: 900;
  line-height: 0.85;
  letter-spacing: -8px;
  color: #FFE600;
}

.hero-stat-label {
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 4px;
  text-transform: uppercase;
  color: rgba(255,255,255,0.5);
  margin-top: 16px;
}

/* Micro labels as design element */
.micro-label {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 3px;
  text-transform: uppercase;
  color: rgba(255,255,255,0.3);
}
```

### Weight Contrast
Use the full Inter weight range (300-900) for expression.

```css
/* Light + Black pairing */
.headline-light {
  font-weight: 300;
  font-size: 64px;
  color: rgba(255,255,255,0.6);
}

.headline-emphasis {
  font-weight: 900;
  color: #FFFFFF;
}

/* Usage: <span class="headline-light">We delivered</span> <span class="headline-emphasis">11 agents</span> */
```

### Letterspacing as Texture
Wide tracking for labels, tight tracking for headlines.

```css
.tracked-wide {
  letter-spacing: 6px;
  text-transform: uppercase;
}

.tracked-tight {
  letter-spacing: -3px;
}
```

---

## Texture and Atmosphere

### Gradient Meshes
Layer multiple gradients for depth. Stay within EY palette.

```css
.premium-gradient-bg {
  background: 
    radial-gradient(ellipse at 20% 80%, rgba(255,230,0,0.08) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, rgba(39,172,170,0.06) 0%, transparent 40%),
    radial-gradient(ellipse at 50% 50%, rgba(24,140,229,0.04) 0%, transparent 60%),
    #0D0D0F;
}

.subtle-glow {
  background: 
    radial-gradient(circle at 30% 70%, rgba(255,230,0,0.1) 0%, transparent 35%),
    #0D0D0F;
}
```

### Noise Texture
Add subtle grain for print-quality feel.

```css
.noise-overlay::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%' height='100%' filter='url(%23noise)'/%3E%3C/svg%3E");
  opacity: 0.03;
  pointer-events: none;
  z-index: 1;
}
```

### Geometric Patterns
Subtle background patterns using CSS.

```css
.dot-pattern {
  background-image: radial-gradient(rgba(255,255,255,0.05) 1px, transparent 1px);
  background-size: 24px 24px;
}

.line-pattern {
  background-image: repeating-linear-gradient(
    90deg,
    rgba(255,255,255,0.03) 0px,
    rgba(255,255,255,0.03) 1px,
    transparent 1px,
    transparent 80px
  );
}
```

---

## Motion and Animation

### Staggered Reveals
Orchestrate entrance for narrative effect.

```css
@keyframes fadeSlideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-in {
  animation: fadeSlideUp 0.8s ease-out forwards;
  opacity: 0;
}

.delay-1 { animation-delay: 0.1s; }
.delay-2 { animation-delay: 0.2s; }
.delay-3 { animation-delay: 0.3s; }
.delay-4 { animation-delay: 0.4s; }

/* Usage: Apply delays to cards/elements in sequence */
```

### Subtle Hover States
Add interactivity cues (works in HTML preview, not PDF).

```css
.interactive-card {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.interactive-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 20px 60px rgba(0,0,0,0.4);
}

.hover-glow:hover {
  box-shadow: 0 0 40px rgba(255,230,0,0.2);
}
```

### Animated Accents
Subtle movement draws attention.

```css
@keyframes pulse-glow {
  0%, 100% { opacity: 0.3; }
  50% { opacity: 0.6; }
}

.accent-pulse {
  animation: pulse-glow 3s ease-in-out infinite;
}

@keyframes gradient-shift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

.animated-gradient {
  background: linear-gradient(90deg, #FFE600, #27ACAA, #188CE5, #FFE600);
  background-size: 300% 100%;
  animation: gradient-shift 8s ease infinite;
}
```

---

## AI-Generated Visual Assets

Use Hugging Face MCP services to create custom imagery that elevates presentations beyond stock photography.

### When to Generate Images

| Slide Type | Generation Approach |
|------------|---------------------|
| Title slides | Abstract hero images, dramatic atmospheres |
| Section dividers | Conceptual visuals matching section theme |
| Background textures | Subtle patterns, gradient meshes |
| Concept illustrations | Abstract representations of ideas |

### Recommended MCP Services

| Service | Best For | EY Usage |
|---------|----------|----------|
| `FLUX.1-Krea-dev` | High-quality artistic images | Hero visuals, abstract backgrounds |
| `Qwen-Image` | Clean, professional images | Conceptual illustrations |
| `FLUX.1-Kontext-Dev` | Editing/transforming images | Adjusting existing visuals |
| `background-removal` | Isolating elements | Cleaning client logos |

### Prompt Patterns for EY-Appropriate Imagery

**Abstract Technology/Innovation:**
```
"Abstract visualization of data flowing through neural networks, dark background #0D0D0F, 
subtle yellow accent highlights #FFE600, minimal, sophisticated, editorial quality, 
no text, professional corporate aesthetic"
```

**Atmospheric Backgrounds:**
```
"Subtle gradient mesh background, deep charcoal to black, hints of gold light, 
minimalist, premium texture, no objects, abstract, suitable for text overlay"
```

**Conceptual Business Imagery:**
```
"Abstract representation of enterprise transformation, geometric shapes, 
dark sophisticated palette with yellow accents, no people, no text, 
editorial magazine quality, corporate premium aesthetic"
```

**Architecture/Structure:**
```
"Abstract architectural visualization, clean lines, dramatic lighting, 
dark background with subtle yellow highlights, minimalist, sophisticated, 
no text, premium corporate style"
```

### Image Integration Guidelines

1. **Always reduce opacity** (15-30%) when using as backgrounds
2. **Add gradient overlay** to ensure text readability
3. **Match color temperature** to EY palette (warm yellows, cool teals)
4. **Avoid literal imagery** — abstract > literal for executive audiences
5. **Test with text overlay** before committing to an image

```css
.generated-bg {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.2;
  z-index: 0;
}

.generated-bg-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(180deg, rgba(13,13,15,0.8) 0%, rgba(13,13,15,0.95) 100%);
  z-index: 1;
}
```

---

## Premium Slide Templates

### Hero Title Slide (Maximum Impact)

```html
<body class="noise-overlay">
  <div class="premium-gradient-bg" style="position:absolute;inset:0;"></div>
  <div class="diagonal-accent"></div>
  
  <div class="content" style="position:relative;z-index:2;">
    <div class="header">
      <span class="micro-label tracked-wide">Client Name | Project Title</span>
      <img src="ey-logo-dark.png" alt="EY" class="ey-logo" />
    </div>
    
    <div style="flex:1;display:flex;align-items:center;">
      <h1 style="font-size:84px;font-weight:900;letter-spacing:-4px;line-height:0.95;">
        <span style="color:rgba(255,255,255,0.6);font-weight:300;">Transforming</span><br>
        <span class="hl">Enterprise AI</span><br>
        <span>Into Reality</span>
      </h1>
    </div>
    
    <div class="footer">
      <span>Confidential</span>
      <span>January 2026</span>
    </div>
  </div>
</body>
```

### Big Number Impact Slide

```html
<div class="content">
  <div class="header">
    <span class="slide-label">The Opportunity</span>
    <img src="ey-logo-dark.png" alt="EY" class="ey-logo" />
  </div>
  
  <div style="display:flex;align-items:center;gap:80px;flex:1;">
    <div>
      <div class="hero-stat">47%</div>
      <div class="hero-stat-label">Efficiency Gain</div>
    </div>
    
    <div style="max-width:600px;">
      <h2 style="font-size:36px;font-weight:700;margin-bottom:24px;">
        Automation delivers measurable ROI within 6 months
      </h2>
      <p style="font-size:19px;color:rgba(255,255,255,0.7);line-height:1.7;">
        Organizations deploying <span class="hl">intelligent automation</span> see 
        productivity improvements of <span class="hl">35-50%</span> across targeted 
        workflows, with full payback in under <span class="hl">180 days</span>.
      </p>
    </div>
  </div>
  
  <div class="footer">...</div>
</div>
```

### Asymmetric Cards Layout

```html
<div class="content">
  <div class="header">...</div>
  
  <h1>Three Pillars of <span class="hl">Enterprise AI</span></h1>
  
  <div style="display:grid;grid-template-columns:1fr 1fr 1.2fr;gap:32px;margin-top:48px;">
    <div class="card animate-in delay-1" style="background:rgba(255,255,255,0.03);border:1px solid rgba(255,255,255,0.08);border-radius:16px;padding:36px;">
      <div class="micro-label" style="color:#FFE600;margin-bottom:16px;">01</div>
      <h3 style="font-size:24px;font-weight:700;margin-bottom:16px;">Foundation</h3>
      <p style="font-size:17px;color:rgba(255,255,255,0.6);line-height:1.6;">
        Data infrastructure and governance frameworks that enable scale.
      </p>
    </div>
    
    <div class="card animate-in delay-2" style="...">
      <div class="micro-label" style="color:#27ACAA;margin-bottom:16px;">02</div>
      <h3>Intelligence</h3>
      <p>AI/ML models trained on enterprise-specific knowledge.</p>
    </div>
    
    <div class="card animate-in delay-3" style="...;border-color:rgba(255,230,0,0.3);">
      <div class="micro-label" style="color:#FFE600;margin-bottom:16px;">03</div>
      <h3>Orchestration</h3>
      <p>Multi-agent systems that coordinate complex workflows.</p>
    </div>
  </div>
  
  <div class="footer">...</div>
</div>
```

---

## Anti-Patterns to Avoid

### Generic AI Aesthetics (Never Do This)
- ❌ Purple/blue gradients on white backgrounds
- ❌ Centered everything with equal spacing
- ❌ Stock photography of handshakes/gears/puzzles
- ❌ Generic icons from icon packs
- ❌ Bullet points for everything
- ❌ Same layout repeated across all slides
- ❌ Safe, predictable compositions

### Instead, Always Ask
- What's the ONE thing someone will remember about this slide?
- Does this feel like a magazine editorial or a corporate template?
- Would I be proud to show this to a Fortune 500 CEO?
- Is there tension, drama, or visual interest?
- Does this slide have a clear visual hierarchy?

---

## Quick Reference: CSS Variables

```css
:root {
  /* Brand (fixed) */
  --ey-yellow: #FFE600;
  --premium-bg: #0D0D0F;
  --text-primary: #FFFFFF;
  --text-secondary: rgba(255,255,255,0.7);
  --text-muted: rgba(255,255,255,0.4);
  
  /* Creative (use these) */
  --card-bg: rgba(255,255,255,0.03);
  --card-border: rgba(255,255,255,0.08);
  --card-border-accent: rgba(255,230,0,0.3);
  --glow-yellow: rgba(255,230,0,0.15);
  --glow-teal: rgba(39,172,170,0.1);
  
  /* Animation timing */
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --duration-fast: 0.2s;
  --duration-medium: 0.4s;
  --duration-slow: 0.8s;
}
```
