# CLAUDE.md — AI Video Producer

## Project

Unified AI video production system. Local-first, ComfyUI-powered, Claude Code-orchestrated.
Merges: ComfyUI Expert (skills), comfyui-pipeline (Python backend), pluralsight-skill (patterns), OpenMontage (concepts).

## Build / Test / Run

```bash
# Install dependencies
uv sync

# Run tests
uv run pytest tests/ -v

# Run specific test module
uv run pytest tests/test_api.py -v

# Launch dashboard (always-on local server)
uv run python scripts/launch_dashboard.py

# Scan ComfyUI inventory
uv run python scripts/scan_inventory.py
```

## Architecture

Three layers:
1. **Claude Code Skills** (`.claude/skills/`) — orchestration, routing, creative decisions
2. **Python Backend** (`src/`) — API clients, validation, state, pipeline execution
3. **Web Dashboard** (`dashboard/`) — visual management, YouTube analytics

## Skill Routing Table

When the user describes what they want to make, route to the appropriate **director skill** first. Director skills are content-type playbooks that recommend workflows, engines, and techniques.

### Director Skills — Content Type Playbooks
| Trigger | Skill | Path |
|---|---|---|
| "talking head", "face to camera", "presenter" | YouTube Talking Head | `director/youtube-talking-head/` |
| "explainer", "educational", "how-to" | YouTube Explainer | `director/youtube-explainer/` |
| "short", "YouTube Short", "60 seconds" | YouTube Short | `director/youtube-short/` |
| "TikTok", "hook", "vertical video" | TikTok Hook | `director/tiktok-hook/` |
| "montage", "music video", "compilation" | Montage | `director/montage/` |
| "tutorial", "screen recording", "walkthrough" | Tutorial | `director/tutorial/` |
| "cinematic", "film", "dramatic" | Cinematic | `director/cinematic/` |
| "auto short", "topic to video", "quick video" | Auto Short | `director/auto-short/` |

### ComfyUI Skills — Infrastructure
| Trigger | Skill | Path |
|---|---|---|
| API calls, queue workflow, check status | ComfyUI API | `comfyui/api/` |
| What models/nodes are available | Inventory | `comfyui/inventory/` |
| Build a workflow JSON | Workflow Builder | `comfyui/workflow-builder/` |
| Optimize a prompt for a specific model | Prompt Engineer | `comfyui/prompt-engineer/` |
| Error, OOM, missing node, generation failed | Troubleshooter | `comfyui/troubleshooter/` |
| New technique, model release, community update | Research | `comfyui/research/` |

### Production Skills — Generation & Assembly
| Trigger | Skill | Path |
|---|---|---|
| Generate character images | Character Gen | `production/character-gen/` |
| Generate video clips | Video Pipeline | `production/video-pipeline/` |
| End-to-end multi-shot video production | Video Production | `production/video-production/` |
| TTS narration, voice cloning, lip-sync | Voice Pipeline | `production/voice-pipeline/` |
| FFmpeg composition, editing, subtitles | Video Assembly | `production/video-assembly/` |
| Train a LoRA, prepare dataset | LoRA Training | `production/lora-training/` |
| User-provided images/videos, "use my assets" | Asset Video | `production/asset-video/` |
| "motion transfer", "animate like this video" | Motion Transfer | `production/motion-transfer/` |
| "What do you want to make?" guided brief | Prompt Interview | `production/prompt-interview/` |

### Publishing Skills — Distribution
| Trigger | Skill | Path |
|---|---|---|
| YouTube upload, metadata, thumbnails | YouTube Publisher | `publishing/youtube/` |
| TikTok formatting, upload | TikTok Publisher | `publishing/tiktok/` |
| Channel analytics, competitor analysis | Analytics | `publishing/analytics/` |

### Utility Skills
| Trigger | Skill | Path |
|---|---|---|
| Project setup, manifest, history | Project Manager | `utility/project-manager/` |
| Remove AI artifacts from text | Humanizer | `utility/humanizer/` |
| Dashboard management | Dashboard | `utility/dashboard/` |

## Routing Rules

1. **Idea → Director Skill first.** When the user has a video idea, read the matching director skill before doing anything else. The director skill tells you the full pipeline, recommended engines, and quality gates.

2. **Director skill → Production skills.** The director skill will reference specific production skills for each pipeline stage. Read those skills when you reach that stage.

3. **Problem → Troubleshooter.** If any generation fails, read the troubleshooter skill before attempting fixes.

4. **Unknown request → Prompt Interview.** If the user's intent is unclear, use the prompt interview skill to clarify what they want to make.

5. **Don't read all skills at once.** Skills are read-on-demand. Only load what's needed for the current stage.

## Context Tiers

### Tier 1 — Foundation (read at session start if relevant)
Files in `foundation/` — hardware profile, model landscape, API quick reference, skill registry.
Small files, always useful. Read when starting a production session.

### Tier 2 — Skills (read on demand)
Files in `.claude/skills/` — detailed playbooks for each capability.
Read only the skill(s) needed for the current task.

### Tier 3 — References (read on demand, large files)
Files in `references/` — full model specs, workflow configurations, training hyperparameters.
Read only when a skill explicitly says to, or when you need deep technical details.

## Key Configuration

- **ComfyUI API:** `http://127.0.0.1:8188` (see `config.yaml`)
- **GPU:** RTX 5090, 32GB VRAM
- **Dashboard:** `http://127.0.0.1:9090`
- **Workflows:** symlinked from `E:\ComfyUI-Easy-Install\ComfyUI\api_workflows\` into `library/workflows/`
- **ComfyUI Backend:** `native` (default) or `comfykit` (async SDK) — set in `config.yaml`

## Project Structure

```
ai-video-producer/
├── .claude/skills/          # Claude Code skills (brain)
│   ├── director/            #   Content-type playbooks
│   ├── comfyui/             #   ComfyUI infrastructure
│   ├── production/          #   Generation & assembly
│   ├── publishing/          #   Distribution
│   └── utility/             #   Project management, tools
├── src/                     # Python backend (hands)
│   ├── api/                 #   ComfyUI REST client
│   ├── pipeline/            #   Pipeline orchestrator
│   ├── gates/               #   5-gate validation
│   ├── registry/            #   Technique catalog
│   ├── bibles/              #   Character bible manager
│   ├── inventory/           #   Node/model discovery
│   ├── scout/               #   Automated discovery
│   ├── discovery/           #   Technique intake
│   ├── assembly/            #   FFmpeg composition
│   ├── tts/                 #   TTS adapters
│   ├── analytics/           #   YouTube analytics engine
│   └── dashboard/           #   Dashboard web server
├── dashboard/               # Web frontend (eyes)
├── foundation/              # Tier 1 context
├── references/              # Tier 3 context
├── library/                 # Organized assets
│   ├── workflows/           #   Categorized workflow JSONs (symlinked)
│   ├── characters/          #   Character bibles + references
│   └── techniques/          #   Technique registry
├── projects/                # Per-project working state
├── state/                   # Runtime state
├── scripts/                 # CLI utilities
└── tests/                   # Test suite (98% coverage target)
```

## Characters

Active characters: **Matt** (real person / creator) and **Sage** (AI character).
Character profiles live in `library/characters/{name}/profile.yaml`.
Sage's character bible is protected — never modify bible fields without explicit confirmation.

## Python Backend

The `src/` package provides reliable execution behind the skills:
- **API client** (`src/api/`) — submit workflows, poll status, retrieve outputs
- **Pipeline** (`src/pipeline/`) — immutable state machine with 5 phases: prepare → build → validate → submit → review
- **Gates** (`src/gates/`) — 5 pre-submission checks: integrity, completeness, metrics, character, quality
- **Registry** (`src/registry/`) — technique catalog with status lifecycle: discovered → tested → validated → deprecated
- **Bibles** (`src/bibles/`) — character profile lookup and method resolution
- **Inventory** (`src/inventory/`) — scan ComfyUI for available nodes and models
- **Scout** (`src/scout/`) — automated discovery from ComfyUI Manager, GitHub, CivitAI, HuggingFace
- **Autoprod** (`src/autoprod/`) — automated multi-scene production orchestrator (topic-to-video, asset-based)
- **MCP Bridge** (`src/mcp_bridge/`) — lightweight MCP server exposing ComfyUI workflows as tools

Skills call Python via: `uv run python -m src.api.client submit workflow.json`

## Workflow with ComfyUI

1. **Never submit a workflow without validation.** Run gates G1-G4 first.
2. **Poll, don't WebSocket.** Claude Code can't hold connections. Poll `/history/{prompt_id}` every 5 seconds.
3. **Check inventory before building.** Verify all nodes and models exist via `src/inventory/`.
4. **Save both formats.** API format (for automation) and UI format (for ComfyUI web editor).

<!-- nexus:start -->
## Nexus Intelligence

*Auto-updated by Nexus — do not edit this section manually.*
*Last sync: 2026-05-11*

### Portfolio
| Project | Description | Tech |
|---------|------------|------|
| jarvis-stack | — | — |
| **ai-video-producer** (this) | — | — |
| personal-brand-assistant | — | — |
| project-avatar | — | — |
| ComfyUI | **ComfyUI** — the main local ComfyUI installation at E:/ComfyUI-Easy-Install/Co… | — |
| matthewkruczek-ai | **matthewkruczek.ai** — static personal brand website for Matthew Kruczek (EY M… | — |
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
- **[security]** Establish clear OPSEC protocol: separate financial accounts, use legal entities…
  > Protects creator identity and finances while maintaining character authenticity; critical for synthetic media operator to separate personal and character business.
- **[security]** Include FTC disclosure compliance in content strategy — all AI influencer conte…
  > Research identified updated FTC requirements effective March 2025 requiring explicit disclosure that influencer is not a real person. This is a legal requirement, not optional.
- **[security]** Use PowerShell script files for complex shell operations to avoid variable esca…
  > Direct bash invocation with variable expansion causes escaping conflicts; writing intermediate `.ps1` scripts and executing via PowerShell eliminates quote/escape issues
- **[security]** Use `--ssl-no-revoke` for curl downloads in PowerShell to bypass SSL validation…
  > Troubleshooting SSL certificate revocation checks during large file downloads from Google Drive and HuggingFace
- **[security]** Use PowerShell ExecutionPolicy Bypass only for inline scripts, not system-wide
  > Limits scope of execution policy override to specific script runs; reduces security surface compared to persistent policy changes

### Active Conflicts
- [medium] jarvis-stack explicitly removes all Anthropic models (Claude) from LLM calls in favor of OpenRouter's Google Gemini + OpenAI GPT only, while ai-video-producer relies on vLLM-served Qwen2.5-VL and project-avatar uses Claude Code via Bifrost MCP — if these projects share infrastructure or decision-making pipelines, the model availability conflict will cause failures.
- [medium] ai-video-producer's vLLM FastAPI QA server (port 8000, Windows E:\ cache paths) cannot run on project-avatar's Mac Mini infrastructure (192.168.50.189) without host OS translation; if ai-video-producer is intended to integrate with Sage/project-avatar workflows, the deployment target must be clarified to avoid port/path conflicts.

> **Cross-project rule**: Before making decisions that affect shared concerns (APIs, auth, data formats, deployment) or asking the user for server/SSH/infrastructure details, run `nexus_query` to check for existing decisions, notes, and conflicts across the portfolio.
> When the user says "save to nexus" or you learn something worth preserving across sessions (project identity, key entities, architecture decisions, cross-project relationships), call `nexus_note` with `action: "set"` and a descriptive `title`.

*[Nexus: `nexus_query` to search | `nexus_note` to save | `nexus_decide` to record decisions]*
<!-- nexus:end -->
