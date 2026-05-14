# project-avatar — AI Avatar / Digital Human

## What This Is

A reimagining of Sage — the OpenClaw AI companion. Where OpenClaw/Sage runs as a text-based agent across messaging channels, project-avatar explores giving Sage (and similar characters) a persistent visual and voice presence: real-time lip-sync, identity-preserving face generation, expressive voice, and an always-on avatar form factor.

**Related MCKRUZ projects:**

- `sage-persona` — **canonical source** for Sage's identity (character bible, soul, voice, world-state). Edit there, sync here.
- `openclaw` — agent gateway (Sage's brain)
- `openclaw-realism` — Sage's personhood framework (persistent mood, proactive outreach)
- `openclaw-voice` — Discord voice bot pipeline (STT → agent → TTS)
- `sage-voice` / `sage-voice-bridge` — TTS/voice synthesis for Sage
- `sage-apartment-skill` — Sage's living world-state (apartment, objects, visual prompts)
- `ComfyUI Expert` — character-consistent image/video generation for Sage

## Stack

- .NET 10, Clean Architecture (Domain → Application → Infrastructure → Host)
- Neo4j graph database (world state, memories, relationships, episodes)
- MediatR for commands/events
- Hangfire for recurring jobs (life tick, memory pruning, episode consolidation)
- Anthropic Claude (Sonnet/Opus for conversations, Haiku for compression/scoring)
- Ollama (nomic-embed-text for embeddings, minicpm-v for vision)
- Google Gemini Flash 2.5 via OpenRouter (life loop, consciousness stream, compression)
- Channels: Discord (text + voice)

## Architecture

Soul-first digital human platform. Sage's identity is defined in markdown files loaded at startup. **Canonical source: `sage-persona/sage/`** — `avatars/sage/` in this repo is a deployment copy. Key subsystems:

- **Conversation** — soul-first prompt assembly, importance-weighted memory retrieval, contextualizer
- **Life Engine** — 30-min tick cycle with emotional drift, consciousness stream, world events
- **Memory** — Neo4j graph: episodes, facts, fragments, summaries. Blended retrieval with semantic search
- **Episode Consolidation** — nightly job merges temporal clusters into story arcs
- **DPO Training Pipeline** — message edits (15x), reactions (10x), Claude scores (1x) → DPO pairs
- **Writing Evaluation** — 6-dimension persona scoring (voice, emotion, knowledge, relationship, naturalness, instruction)
- **Voice** — Whisper STT → LLM → Chatterbox TTS, streaming pipeline with interruption support

## Code Style

Follow global conventions in `~/.claude/rules/coding-style.md`:

- Immutable patterns (record types for DTOs, no mutation)
- Small focused files (200-400 lines typical, 800 max)
- Clean Architecture: Domain → Application → Infrastructure → Host
- CQRS via MediatR for commands/queries
- FluentValidation for all input

## Commands

- `dotnet build src/Avatar.Host/Avatar.Host.csproj` — build
- `dotnet test tests/Avatar.Application.Tests/` — run unit tests
- `./redeploy-mac.sh` — deploy to Mac Mini (publish → build arm64 → stream → restart)

## Verification

After changes: `dotnet build src/Avatar.Host/Avatar.Host.csproj && dotnet test tests/Avatar.Application.Tests/`

## Key References

- Hardware: RTX 5090 (32GB VRAM), `--highvram --fp8_e4m3fn-unet` for ComfyUI
- ComfyUI API: `http://FURIOUS:8188` — POST to `/prompt`, poll `/history`
- Chatterbox TTS: `http://FURIOUS:5000` — used in ProjectPrism voice pipeline
- OpenClaw gateway: `openclaw-gateway` container on `bablyon` NAS
- Langfuse observability: `https://langfuse.bablyon.synology.me`

## Common Mistakes

_(Populate as you find them)_

---

<!-- nexus:start -->
## Nexus Intelligence

*Auto-updated by Nexus — do not edit this section manually.*
*Last sync: 2026-05-08*

### Portfolio
| Project | Description | Tech |
|---------|------------|------|
| jarvis-stack | — | — |
| ai-video-producer | — | — |
| personal-brand-assistant | — | — |
| **project-avatar** (this) | — | — |
| ComfyUI | **ComfyUI** — the main local ComfyUI installation at E:/ComfyUI-Easy-Install/Co… | — |
| matthewkruczek-ai | **matthewkruczek.ai** — static personal brand website for Matthew Kruczek (EY M… | — |
| claude-code-mastery | **Claude Code Mastery** — the definitive Claude Code setup and configuration sk… | — |
| Nexus | Nexus is a local-first cross-project intelligence layer for Claude Code. | — |
| _+32 inactive_ | — | — |

### Project Context
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

### Context from ComfyUI
#### Fish Audio S2 — Voice Generation Pipeline
**Date:** 2026-03-30

## Fish Audio S2 Pro — Voice Clone TTS for Sage

**Status:** WORKING — replaces Voicebox as primary voice generation
**ComfyUI …
*Tags: sage, tts, voice, fish-audio, pipeline*

#### Sage Bible v3.3 — Z-Image LoRA Update
**Date:** 2026-03-29

Sage Character Bible updated to v3.3. Key changes:

- **Z-Image Turbo is now PRIMARY model** (replaces FLUX.1 as default)
- New…
*Tags: sage, bible, lora, z-image, v3.3*

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

### Recorded Decisions
- **[security]** Enforce path traversal rejection in IdentityFileWriter.ValidateChange() and fre…
  > Prevents injection attacks on markdown-based identity persistence; frozen zones (core personality traits) act as implicit safety bounds
- **[security]** Implement path traversal validation and bumper enforcement on identity file wri…
  > Prevents LLM from escaping intended file boundaries; enforces semantic constraints (frozen zones cannot change) even if synthesis produces invalid mutations
- **[security]** GrowthSeeds include optional PersonId linking but do not store personally ident…
  > Maintains privacy boundaries while allowing relational growth tracking. Observation text remains analyzable without exposing sensitive details about conversation partners. Aligns with earlier conversation constraints on PII handling.

### Active Conflicts
- [high] project-avatar relies on Claude Haiku for daily reflection and assumes Claude API access for learning signals; jarvis-stack explicitly excludes all Anthropic models (Google Gemini + OpenAI GPT only)—if both projects share infrastructure or Sage identity is consumed by jarvis-stack services, the reflection pipeline breaks.
- [high] project-avatar uses Claude API as primary reasoner while jarvis-stack explicitly replaces all Anthropic models with Google Gemini + OpenAI GPT only; projects sharing a backend or conversation pipeline cannot coexist without model strategy reconciliation.
- [high] project-avatar relies on Claude API (Haiku) for core LLM decisions while jarvis-stack explicitly excludes Anthropic models and uses only Google Gemini + OpenAI GPT—if these projects share infrastructure or decisions, the model tier strategy will conflict.
- [medium] jarvis-stack explicitly removes all Anthropic models (Claude) from LLM calls in favor of OpenRouter's Google Gemini + OpenAI GPT only, while ai-video-producer relies on vLLM-served Qwen2.5-VL and project-avatar uses Claude Code via Bifrost MCP — if these projects share infrastructure or decision-making pipelines, the model availability conflict will cause failures.
- [medium] ai-video-producer's vLLM FastAPI QA server (port 8000, Windows E:\ cache paths) cannot run on project-avatar's Mac Mini infrastructure (192.168.50.189) without host OS translation; if ai-video-producer is intended to integrate with Sage/project-avatar workflows, the deployment target must be clarified to avoid port/path conflicts.

> **Cross-project rule**: Before making decisions that affect shared concerns (APIs, auth, data formats, deployment) or asking the user for server/SSH/infrastructure details, run `nexus_query` to check for existing decisions, notes, and conflicts across the portfolio.
> When the user says "save to nexus" or you learn something worth preserving across sessions (project identity, key entities, architecture decisions, cross-project relationships), call `nexus_note` with `action: "set"` and a descriptive `title`.

*[Nexus: `nexus_query` to search | `nexus_note` to save | `nexus_decide` to record decisions]*
<!-- nexus:end -->
