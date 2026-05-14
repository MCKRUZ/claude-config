
<!-- nexus:start -->
## Nexus Intelligence

*Auto-updated by Nexus — do not edit this section manually.*
*Last sync: 2026-04-15*

### Portfolio
| Project | Description | Tech |
|---------|------------|------|
| **jarvis-stack** (this) | — | — |
| personal-brand-assistant | — | — |
| project-avatar | — | — |
| ComfyUI | **ComfyUI** — the main local ComfyUI installation at E:/ComfyUI-Easy-Install/Co… | — |
| matthewkruczek-ai | **matthewkruczek.ai** — static personal brand website for Matthew Kruczek (EY M… | — |
| claude-code-mastery | **Claude Code Mastery** — the definitive Claude Code setup and configuration sk… | — |
| ComfyUI Expert | **VideoAgent / ComfyUI Expert** — session-scoped Claude Code orchestrator that … | — |
| Nexus | Nexus is a local-first cross-project intelligence layer for Claude Code. | — |
| _+31 inactive_ | — | — |

### Project Context
#### OpenRouter LLM Configuration
## OpenRouter — Jarvis LLM Provider (since 2026-04-03)

All Jarvis LLM calls go through OpenRouter. No Anthropic/Claude models — Google and OpenAI on…
*Tags: openrouter, llm, jarvis, cost-optimization*

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

### Context from openclaw
#### OpenClaw Ollama Integration & Stop Hook Architecture
(1) OpenClaw uses agent model fallback chains requiring tool-capable models (Claude Opus/Sonnet, llama3.1:8b); (2) Two separate Ollama patterns: Open…

### Recorded Decisions
- **[architecture]** Replace OpenClaw/SSH Claude CLI with OpenRouter API for all LLM calls — tiered …
  > User banned all Anthropic model usage. OpenRouter provides OpenAI-compatible API with per-call model selection. Tiered approach matches model cost to task complexity: Gemini 2.5 Pro for decomposition ($1.25/$10/M), Gemini 2.0 Flash for quality checks ($0.10/$0.40/M), GPT-5 Nano for summarization ($0.05/$0.40/M), Gemini 2.5 Flash for HUD chat (~$0.15/$1.25/M). Removed openclaw-gateway, openclaw-cli, and clawteam services from docker-compose.

> **Cross-project rule**: Before making decisions that affect shared concerns (APIs, auth, data formats, deployment) or asking the user for server/SSH/infrastructure details, run `nexus_query` to check for existing decisions, notes, and conflicts across the portfolio.

*[Nexus: run `nexus query` to search full knowledge base]*
<!-- nexus:end -->
