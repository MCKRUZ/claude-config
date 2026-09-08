# LLM Model Pricing Reference

Last updated: 2026-03-13

## Pricing Table

| Provider | Model ID | Input $/M tokens | Output $/M tokens | Best For |
|----------|----------|------------------:|-------------------:|----------|
| Anthropic | `claude-opus-4-6` | $15.00 | $75.00 | Complex reasoning, emotional nuance, creative writing |
| Anthropic | `claude-sonnet-4-6` | $3.00 | $15.00 | Standard tasks, code generation, analysis |
| Anthropic | `claude-haiku-4-5-20251001` | $1.00 | $5.00 | Simple tasks, classification, summarization |
| OpenRouter | `google/gemini-2.5-flash` | $0.30 | $2.50 | Structured extraction, compression, formatting |
| OpenRouter | `google/gemini-2.5-pro` | $1.25 | $10.00 | Complex reasoning (budget Sonnet alternative) |
| Local | Ollama (`qwen2.5:32b` etc.) | $0.00 | $0.00 | Recurring background tasks, no latency SLA |

## Cost Comparison (relative to Sonnet baseline)

| Model | Input Cost vs Sonnet | Output Cost vs Sonnet |
|-------|---------------------:|----------------------:|
| Opus | 5x more | 5x more |
| Sonnet | baseline | baseline |
| Haiku | 3x cheaper | 3x cheaper |
| Gemini Flash | 10x cheaper | 6x cheaper |
| Gemini Pro | 2.4x cheaper | 1.5x cheaper |
| Ollama | free | free |

## Savings Estimation

To estimate monthly savings for a model swap:
1. Estimate monthly token volume (input + output) for the call site
2. Calculate current cost: `(input_tokens / 1M * input_price) + (output_tokens / 1M * output_price)`
3. Calculate new cost with recommended model
4. Delta = current - new

Rule of thumb for typical MCKRUZ projects:
- Light usage (~1M tokens/mo): Sonnet→Haiku saves ~$7/mo, Sonnet→Flash saves ~$12/mo
- Medium usage (~5M tokens/mo): Sonnet→Haiku saves ~$35/mo, Sonnet→Flash saves ~$60/mo
- Heavy usage (~20M tokens/mo): Sonnet→Haiku saves ~$140/mo, Sonnet→Flash saves ~$240/mo

## OpenRouter Notes

- OpenRouter adds a small markup over base model pricing
- Provides access to non-Anthropic models (Gemini, Llama, Mistral) via OpenAI-compatible API
- Requires `OPENROUTER_API_KEY` and base URL `https://openrouter.ai/api/v1`
- Model IDs use `provider/model` format (e.g., `google/gemini-2.5-flash`)
