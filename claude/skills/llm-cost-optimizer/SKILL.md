---
name: llm-cost-optimizer
description: >
  Audit and optimize LLM model selections for cost efficiency. Triggers when code
  uses direct API keys to call LLMs (Anthropic SDK, OpenRouter, OpenAI-compatible
  endpoints). Scans call sites, classifies by complexity tier, and recommends
  cheaper model alternatives. Use when creating new LLM integrations, reviewing
  model choices, or optimizing API spend. Does NOT trigger for OpenClaw
  gateway/OAuth-routed calls.
allowed-tools: Read, Glob, Grep, Agent
---

# LLM Cost Optimizer

Audit LLM model selections across a project and recommend cost-efficient alternatives.

## Trigger Conditions

Activate when the current project:
- Imports `@anthropic-ai/sdk`, `Anthropic.SDK`, `OpenAI`, or `openai`
- Contains API key configuration for LLM providers (not OAuth/gateway)
- Creates LLM clients with hardcoded model IDs
- Has `appsettings.json` or config files with model routing sections

Do NOT trigger for:
- OpenClaw gateway code (uses OAuth/WebSocket, not direct API keys)
- General coding tasks unrelated to LLM integration
- Projects that only consume LLM output via intermediary services

## Audit Workflow

### Step 1: Load References

Read the reference files in this skill's `references/` directory:
- `model-pricing.md` — current pricing for all providers
- `tiering-decision-matrix.md` — decision tree for model selection
- `implementation-patterns.md` — battle-tested code patterns

### Step 2: Scan

Find all LLM call sites in the project:

```
Search for:
- SDK imports: @anthropic-ai/sdk, Anthropic.SDK, OpenAI, openai
- Client constructors: new Anthropic(, new OpenAI(, ChatClient(
- Model ID strings: claude-opus, claude-sonnet, claude-haiku, gpt-4, gemini
- Config files: appsettings*.json, config.yaml, .env with model/API key entries
- OpenRouter usage: openrouter.ai, OPENROUTER_API_KEY
```

For each call site, record:
1. File path and line number
2. Current model being used
3. What the call does (summarize the prompt/purpose)
4. Whether the model is hardcoded or configurable

### Step 3: Classify

Categorize each call site by complexity tier using the decision matrix:

| Tier | Task Types | Target Models |
|------|-----------|---------------|
| **Lightweight** | Structured extraction, compression, summaries, formatting, simple Q&A | Gemini Flash, Haiku |
| **Standard** | Code generation, multi-step reasoning, analysis | Haiku, Sonnet |
| **Complex** | Creative writing, emotional nuance, deep judgment | Sonnet, Opus |
| **Background** | Recurring jobs, no latency SLA | Local (Ollama) |

### Step 4: Report

Present findings as a table:

```
| # | File:Line | Purpose | Current Model | Recommended | Est. Savings |
|---|-----------|---------|---------------|-------------|-------------|
| 1 | src/ai.ts:42 | Extract entities | claude-sonnet-4-6 | gemini-flash | ~80% |
| 2 | ... | ... | ... | ... | ... |
```

Calculate estimated monthly savings based on:
- Pricing differentials from `model-pricing.md`
- Rough token volume estimates (ask the user if unknown)

### Step 5: Recommend

For each finding, suggest specific changes following established patterns:

1. **Make models configurable** — never hardcode model IDs. Use config files with cost comments.
2. **Use ResilientChatClient pattern** — primary (cheap) → fallback (reliable) chains.
3. **Route via OpenRouter** for non-Anthropic models (Gemini Flash, etc.).
4. **Add cost comments** to config entries so future developers understand the tradeoffs.

Reference `implementation-patterns.md` for concrete code examples in C#, Python, and TypeScript.

## Output Format

Always end the audit with:

1. **Summary table** of all call sites with recommendations
2. **Total estimated savings** (monthly)
3. **Priority order** — which changes give the most savings for least effort
4. **Code snippets** for the top 3 highest-impact changes
