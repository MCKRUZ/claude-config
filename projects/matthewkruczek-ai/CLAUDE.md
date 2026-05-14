# matthewkruczek.ai - Personal Brand Website

## Project Overview
Static HTML/CSS/JS personal brand website for Matthew Kruczek (EY Managing Director). Premium executive-level design showcasing AI/enterprise thought leadership through blog content.

## Stack
- **Frontend**: Pure HTML5, CSS3 (custom properties), Vanilla JavaScript
- **Design System**: Dark theme with amber/gold accents (#d4a853)
- **Typography**: Playfair Display (headlines), Source Sans 3 (body), JetBrains Mono (code)
- **Hosting**: Netlify/Vercel/GitHub Pages → matthewkruczek.ai
- **Build**: None required (static files)

## Architecture
```
matthewkruczek-ai/
├── index.html          # Main landing page
├── blog.html           # Blog listing with filters
├── blog/               # Individual blog posts (31 articles)
├── css/styles.css      # Shared design system
├── assets/
│   ├── webmcp.js       # WebMCP implementation (AI-agent tools)
│   ├── headshot.jpg
│   └── Matthew_Kruczek_CV.pdf
└── docs/
    └── ai-agent-ready/  # AI-agent implementation documentation
        ├── README.md
        ├── implementation-guide.md
        └── claude-code-prompt.md
```

## AI-Agent Readiness

This website implements **two protocols** to make it AI-agent native:

### 1. WebMCP (Web Model Context Protocol) ✅ IMPLEMENTED
- **Location**: `/assets/webmcp.js`
- **Integrated**: index.html, blog.html, all 31 blog posts
- **Browser Support**: Chrome 146+ with WebMCP EPP enabled
- **Graceful Degradation**: No-op in unsupported browsers (zero user impact)

**5 Tools Exposed to AI Agents**:
1. `getProfile` - Professional profile (role, company, bio, credentials, stats)
2. `getExpertise` - Areas of expertise with descriptions
3. `getSpeakingTopics` - Keynote and executive briefing topics
4. `getArticles` - Blog articles with categories, summaries, URLs
5. `getContactInfo` - Contact preferences by inquiry purpose

**Verification**: Open Chrome 146+ DevTools console, should see:
```
[WebMCP] 5 tools registered: getProfile, getExpertise, getSpeakingTopics, getArticles, getContactInfo
```

### 2. Cloudflare Markdown for Agents ⏳ PENDING
- **Status**: Requires manual DNS configuration (see docs/ai-agent-ready/implementation-guide.md)
- **Benefit**: 80% token reduction for AI crawlers (HTML → clean markdown)
- **Content Signals**: `ai-train=yes, search=yes, ai-input=yes`

**Testing After Setup**:
```bash
curl -s "https://matthewkruczek.ai" -H "Accept: text/markdown" | head -30
curl -sI "https://matthewkruczek.ai" -H "Accept: text/markdown" | grep "x-markdown-tokens"
```

### Why This Matters
When someone asks Claude, ChatGPT, or any AI: *"Tell me about Matthew Kruczek"*:
- ✅ Agent gets **structured JSON** from WebMCP tools (not scraped HTML)
- ✅ Agent processes **80% fewer tokens** via Markdown for Agents
- ✅ Response is **accurate, authoritative, and cited** (not paraphrased guesswork)

This makes matthewkruczek.ai one of the **first executive portfolio sites in the world** that's fully AI-agent native.

**Full Documentation**: See [docs/ai-agent-ready/](./docs/ai-agent-ready/)

## Code Conventions

### HTML
- Semantic HTML5 elements (article, section, nav, etc.)
- Accessible markup (ARIA labels, alt text, semantic structure)
- SEO optimized (meta tags, Open Graph, schema.org)
- Consistent class naming: `.component-element` pattern

### CSS
- CSS custom properties for design tokens (see `:root` in styles.css)
- Mobile-first responsive design (breakpoints: 768px, 1024px)
- BEM-like naming for components
- Smooth animations via CSS transitions (avoid JS where possible)

### JavaScript
- Vanilla JS only (no frameworks/libraries)
- Progressive enhancement (site works without JS)
- Minimal DOM manipulation
- Event delegation for performance

### Blog Posts
Each blog post follows consistent structure:
1. Full HTML document with shared styles
2. Header with navigation back to blog
3. Article metadata (date, category, reading time)
4. Semantic article content with proper heading hierarchy
5. Related posts section
6. Footer with call-to-action

## Global Rules Reference
See `~/.claude/rules/` for comprehensive guidelines:
- **coding-style.md** - Immutability, file organization, error handling
- **git-workflow.md** - Commit messages, PR workflow
- **security.md** - Input validation, XSS prevention
- **performance.md** - Model selection, context management

For this static site project, most relevant rules:
- ✅ Immutability patterns (when adding JS state)
- ✅ Git workflow (conventional commits)
- ✅ Security (XSS prevention in any dynamic content)
- ⚠️ Skip: Testing requirements (no test suite for static site)
- ⚠️ Skip: C#/Angular patterns (not applicable)

## Commands
```bash
# Development (simple HTTP server)
python -m http.server 8000
# OR
npx serve

# Validate HTML
npx html-validate index.html blog.html blog/*.html

# Optimize images
npx imagemin assets/**/*.{jpg,png} --out-dir=assets/

# Deploy to Netlify (manual)
netlify deploy --prod

# Check links
npx broken-link-checker http://localhost:8000
```

## Verification
After changes:
1. View in browser (test responsive breakpoints)
2. Validate HTML markup
3. Check accessibility (WCAG compliance)
4. Test on mobile device or DevTools mobile emulation

## Task Approach
When given a feature request or task:
1. **Clarify scope**: Is this a new blog post, design change, or new feature?
2. **Check consistency**: New elements should match existing design system
3. **Preserve accessibility**: Maintain semantic HTML and ARIA labels
4. **Test responsive**: Changes should work on mobile, tablet, desktop
5. **Update all instances**: Blog post templates should stay consistent

## Content Guidelines

### Adding New Blog Posts
1. Copy existing blog post as template (e.g., `blog/agent-first-enterprise.html`)
2. Update metadata: title, description, date, category, reading time
3. Update Open Graph tags for social sharing
4. Add post card to `blog.html` in chronological order
5. Optimize featured image (WebP preferred, max 1200px wide)
6. Update category filters if introducing new category

### Design System Colors
Reference CSS variables in `css/styles.css:root`:
- Primary backgrounds: `--bg-primary`, `--bg-secondary`, `--bg-tertiary`
- Accent: `--accent-gold` (#d4a853) - executive premium feel
- Text: `--text-primary`, `--text-secondary`, `--text-muted`

### Typography Scale
- Hero headlines: `clamp(2.5rem, 5vw, 4rem)`
- Section headlines: `clamp(1.75rem, 3vw, 2.5rem)`
- Body text: 1.125rem (18px) for readability
- Code blocks: JetBrains Mono 0.9rem

## SEO Best Practices
- Unique meta descriptions (150-160 characters)
- Descriptive page titles (50-60 characters)
- Semantic heading hierarchy (single h1, logical h2-h6)
- Alt text for all images
- Structured data (JSON-LD) for articles
- Internal linking between blog posts

## Publishing Workflow: Substack First, Blog Second

All new blog posts follow a **Substack-first** schedule:
1. **Write** — create article content (can start in `blog/drafts/` as `.md`)
2. **Substack draft** — save clean markdown to `substack/[slug].md` (gitignored, never pushed)
3. **Cover image** — generate via ComfyUI + Pillow text overlay, save to `assets/blog-images/[slug].png`
4. **Publish to Substack** — use `substack/preview.html` to convert markdown → rich text → paste into Substack editor
5. **Wait ~1 week**
6. **Publish to blog** — create `blog/[slug].html` from the article, add card to `blog.html`, commit & push

### Using the Substack Preview Tool

Open `substack/preview.html` in a browser (no server needed):
1. Paste your markdown from `substack/[slug].md` into the left panel
2. Rendered Substack-ready output appears on the right
3. Click **Select & Copy** (or `Ctrl+Enter`)
4. Paste directly into the Substack editor — formatting comes through intact

`[INSERT IMAGE: ...]` placeholders show as dashed boxes — upload images manually in Substack at those spots.

### Substack Folder Structure
```
substack/          ← gitignored, local only
├── preview.html   ← the copy-paste tool
├── [slug].md      ← one file per pending article
└── ...
```

## Common Tasks

### Update CV
1. Edit source document
2. Export to PDF
3. Replace `assets/Matthew_Kruczek_CV.pdf`
4. Verify download link works

### Change Theme Colors
Edit CSS custom properties in `css/styles.css`:
```css
:root {
    --accent-gold: #d4a853;        /* Update here */
    --accent-gold-dim: #b8923f;
    --accent-gold-glow: rgba(212, 168, 83, 0.15);
}
```

### Add New Section to Homepage
1. Follow existing section structure
2. Use fade-in animation class: `class="fade-in"`
3. Maintain responsive grid patterns
4. Update anchor links in navigation

## Accessibility Checklist
- [ ] Semantic HTML elements used
- [ ] Alt text on all images
- [ ] ARIA labels on interactive elements
- [ ] Keyboard navigation works
- [ ] Sufficient color contrast (4.5:1 minimum)
- [ ] Focus indicators visible
- [ ] Screen reader tested (if possible)

## Performance Optimization
- Minimize HTTP requests (inline critical CSS if needed)
- Optimize images (WebP with fallback, lazy loading)
- Defer non-critical JavaScript
- Use system fonts where possible
- Avoid layout shifts (specify image dimensions)

## Deployment
Primary: **Netlify** (continuous deployment from git)
1. Push changes to main branch
2. Netlify auto-deploys
3. Verify at matthewkruczek.ai

Manual deploy:
```bash
netlify deploy --prod --dir=.
```

## Common Mistakes to Avoid
- ❌ Don't add build tools/frameworks - keep it simple static HTML
- ❌ Don't break responsive design - test all breakpoints
- ❌ Don't use inline styles - use CSS custom properties
- ❌ Don't forget Open Graph tags on new blog posts
- ❌ Don't skip accessibility - executive audience includes diverse users
- ❌ Don't use generic meta descriptions - each page needs unique SEO

## Agent Usage Recommendations
For this project, these agents are most valuable:
- **code-reviewer** - After HTML/CSS changes, check accessibility and best practices
- **security-reviewer** - If adding any dynamic features or forms
- **doc-updater** - Keep README.md and this CLAUDE.md in sync

Skip these agents (not applicable):
- tdd-guide (no test suite for static site)
- build-error-resolver (no build process)
- refactor-cleaner (simple structure, minimal dead code risk)

<!-- nexus:start -->
## Nexus Intelligence

*Auto-updated by Nexus — do not edit this section manually.*
*Last sync: 2026-05-11*

### Portfolio
| Project | Description | Tech |
|---------|------------|------|
| jarvis-stack | — | — |
| ai-video-producer | — | — |
| personal-brand-assistant | — | — |
| project-avatar | — | — |
| ComfyUI | **ComfyUI** — the main local ComfyUI installation at E:/ComfyUI-Easy-Install/Co… | — |
| **matthewkruczek-ai** (this) | **matthewkruczek.ai** — static personal brand website for Matthew Kruczek (EY M… | — |
| claude-code-mastery | **Claude Code Mastery** — the definitive Claude Code setup and configuration sk… | — |
| Nexus | Nexus is a local-first cross-project intelligence layer for Claude Code. | — |
| _+32 inactive_ | — | — |

### Context from personal-brand-assistant
#### Deployment: Local Docker on Furious
## PBA Deployment

- **Host:** Furious (local machine)
- **Runtime:** Docker Compose
- **Branch deployed:** main
- **Last known deploy:** manual, nee…
*Tags: deployment, docker, furious, infrastructure*

#### Website Analytics: Google Search Console + GA4
## Website Analytics for matthewkruczek.ai

### Service Account Credentials
- **File:** `secrets/google-analytics-sa.json` (gitignored)
- **Email:** …
*Tags: analytics, google-search-console, ga4, matthewkruczek-ai, seo, website-stats*

### Context from project-avatar
#### Civitai API Key
## Civitai API Key

**Key:** `f3c2926aa7fcc3919915fd3a079b7f21`

**Use:** Civitai model downloads via API (`https://civitai.com/api/download/models/{…
*Tags: civitai, api-key, credentials, download, lora*

#### VoiceBox TTS — Sage Voice Generation (Jennifer Garner Clone)
## VoiceBox TTS for Sage

**App:** `C:\Users\kruz7\AppData\Local\Voicebox\voicebox.exe` (desktop app, auto-starts server)
**API:** `http://127.0.0.1:…
*Tags: voicebox, tts, voice-clone, jennifer-garner, sage-voice, api, furious*

#### Mac Mini SSH & Infrastructure
## Mac Mini (PRIMARY — Sage lives here)

- **Host:** 192.168.50.189
- **SSH:** `ssh matthewkruczek@192.168.50.189`
- **Platform:** Apple Silicon (arm…
*Tags: infrastructure, ssh, mac-mini, deployment, neo4j, docker*

### Recorded Decisions
- **[security]** Disconnect and reconnect GitHub repository webhooks rather than destructive unl…
  > Developer expressed caution about full unlink (described as 'deletes keys, hooks, resets settings'); prefers non-destructive re-authorization via 'Configure' button
- **[security]** Authenticate Netlify CLI via browser OAuth during login rather than managing pe…
  > Browser OAuth flow is more secure and user-friendly; CLI stores token locally after OAuth completion, reducing credential exposure risk
- **[security]** Use browser OAuth flow with Netlify CLI for authentication
  > Avoids storing plaintext auth tokens in environment variables. Accepts OAuth from identity providers (Google) linked to Netlify account without complications.
- **[security]** Leverage Netlify OAuth browser flow for authentication rather than storing pers…
  > Google OAuth is linked to Netlify account, CLI OAuth flow is secure and token is stored locally; avoids exposing auth tokens in env configuration
- **[security]** Use hypothetical scenarios and anonymized organizational examples rather than s…
  > Maintains credibility without revealing confidential client information or project details

> **Cross-project rule**: Before making decisions that affect shared concerns (APIs, auth, data formats, deployment) or asking the user for server/SSH/infrastructure details, run `nexus_query` to check for existing decisions, notes, and conflicts across the portfolio.
> When the user says "save to nexus" or you learn something worth preserving across sessions (project identity, key entities, architecture decisions, cross-project relationships), call `nexus_note` with `action: "set"` and a descriptive `title`.

*[Nexus: `nexus_query` to search | `nexus_note` to save | `nexus_decide` to record decisions]*
<!-- nexus:end -->
