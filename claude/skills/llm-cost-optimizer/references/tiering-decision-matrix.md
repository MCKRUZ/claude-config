# Model Tiering Decision Matrix

## Decision Tree

Ask these questions in order to determine the right model tier:

### 1. Is it a recurring background job with no latency requirement?
**Yes → Local (Ollama)**
- Examples: nightly batch processing, index rebuilding, periodic summarization
- Requirement: task can tolerate 10-30s latency, runs on infrastructure with GPU access

### 2. Is it structured extraction, compression, or simple formatting?
**Yes → Gemini Flash**
- Structured data extraction from text (JSON output)
- Text compression / summarization of straightforward content
- Simple formatting, templating, or transformation
- Visual prompt generation from structured input
- Consciousness stream compression (project-avatar pattern)

### 3. Is it classification, simple Q&A, or basic summarization?
**Yes → Haiku**
- Intent classification, sentiment analysis
- Simple question answering against provided context
- Basic summarization where nuance isn't critical
- Validation, checking, or verification tasks
- Default model for new integrations (start cheap, upgrade if quality is insufficient)

### 4. Is it code generation, multi-step reasoning, or detailed analysis?
**Yes → Sonnet**
- Code generation, review, or transformation
- Multi-step reasoning chains
- Detailed analysis requiring nuanced understanding
- Tasks where Haiku quality is demonstrably insufficient

### 5. Does it require emotional nuance, creative writing, or complex judgment?
**Yes → Opus**
- Character voice / personality (e.g., relationship interactions in project-avatar)
- Creative writing requiring consistent tone and depth
- Complex ethical or emotional judgment calls
- Tasks where Sonnet quality is demonstrably insufficient

## Fallback Chain Strategy

Always configure a fallback for production systems:

| Primary | Fallback | When |
|---------|----------|------|
| Gemini Flash | Haiku | Flash is unavailable or rate-limited |
| Haiku | Sonnet | Haiku gives poor quality for specific task |
| OpenRouter model | Direct Anthropic | OpenRouter is down |

## When to Make Models Configurable vs Hardcoded

**Always configurable:**
- Any model choice that might need tuning based on quality/cost tradeoff
- Any production system where you might need to swap models without redeploying
- Multi-environment setups (dev might use cheaper models than prod)

**Acceptable to hardcode (rare):**
- One-off scripts or tools not in production
- When the model is fundamental to the feature (e.g., Opus for a feature that specifically requires Opus-level reasoning)

## Starting Point Rule

> **Default to Haiku. Only upgrade when you can demonstrate the task needs it.**

This inverts the common pattern of defaulting to the most capable model. Most tasks work fine with Haiku. Upgrade to Sonnet only when testing shows Haiku is insufficient. Reserve Opus for tasks that genuinely require it.
