# Implementation Patterns

Battle-tested code patterns from project-avatar, openclaw-voice, and Nexus.

## C# Pattern: Resilient Fallback Chains (project-avatar)

### IntelligenceRouter — Model routing by request type

```csharp
// Route requests to appropriate model tier
public IChatClient GetClient(RoutingRequest request) => request.RequestType switch
{
    RequestType.LifeLoop            => _localResilient,        // Local Ollama
    RequestType.Relationship        => BuildAnthropicClient(_options.Anthropic.OpusModel),
    RequestType.Assessment          => BuildAnthropicClient(_options.Anthropic.SonnetModel),
    RequestType.Compression         => _lightweightClient,     // Gemini Flash → Haiku
    RequestType.ConsciousnessStream => _lightweightClient,
    RequestType.VisualPrompt        => _lightweightClient,
    _ => throw new ArgumentOutOfRangeException(nameof(request)),
};
```

### BuildLightweightClient — Gemini Flash with Haiku fallback

```csharp
private IChatClient BuildLightweightClient()
{
    if (!_options.OpenRouter.IsConfigured)
        return BuildAnthropicClient(_options.Anthropic.HaikuModel);

    var primary = BuildOpenRouterClient(_options.OpenRouter.GeminiFlashModel);
    var fallback = new LazyAnthropicClient(
        () => ResolveApiKey(), _options.Anthropic.HaikuModel);

    return new ResilientChatClient(
        primary, fallback, _anthropicPipeline,
        _loggerFactory.CreateLogger<ResilientChatClient>(),
        _fallbackTracker);
}
```

### ResilientChatClient — Automatic fallback on failure

```csharp
public override async Task<ChatResponse> GetResponseAsync(
    IEnumerable<ChatMessage> messages,
    ChatOptions? options = null,
    CancellationToken cancellationToken = default)
{
    try
    {
        return await _pipeline.ExecuteAsync(
            async ct => await InnerClient.GetResponseAsync(msgList, options, ct),
            cancellationToken);
    }
    catch (Exception ex) when (ex is not OperationCanceledException)
    {
        _logger.LogWarning(ex, "Primary client unavailable — falling back");
        _tracker?.RecordFallback(
            InnerClient.GetType().Name, _fallback.GetType().Name, ex.Message);
        return await _fallback.GetResponseAsync(
            msgList, StripModelId(options), cancellationToken);
    }
}

// Fallback uses its own configured model, not the primary's
private static ChatOptions? StripModelId(ChatOptions? options) => options is not null
    ? new ChatOptions { Temperature = options.Temperature, MaxOutputTokens = options.MaxOutputTokens }
    : null;
```

### Config with cost comments (appsettings.json)

```json
{
  "Anthropic": {
    "HaikuModel": "claude-haiku-4-5-20251001",  // $1/$5 per M tokens
    "SonnetModel": "claude-sonnet-4-6",          // $3/$15 per M tokens
    "OpusModel": "claude-opus-4-6"               // $15/$75 per M tokens
  },
  "OpenRouter": {
    "GeminiFlashModel": "google/gemini-2.5-flash" // $0.30/$2.50 per M tokens
  }
}
```

---

## Python Pattern: Optional Model Threading (openclaw-voice)

### Config with tiered models

```yaml
llm:
  default_model: "claude-haiku-4-5-20251001"  # Haiku: $1/$5 per M tokens
  complex_model: "claude-sonnet-4-6"           # Sonnet: $3/$15 per M tokens
  timeout_seconds: 120
```

### Optional model parameter threaded through call chain

```python
async def send_message(
    self,
    agent: str,
    message: str,
    context: str = "",
    speaker: Optional[str] = None,
    model: Optional[str] = None,  # Optional override
) -> str:
    response = await self._send_chat(
        session_key, message, timeout=self.config.timeout, model=model
    )

async def _send_chat(
    self, session_key: str, message: str,
    timeout: float = 120, model: Optional[str] = None
) -> str:
    params = {
        "sessionKey": session_key,
        "message": message,
        "deliver": True,
    }
    if model:
        params["model"] = model  # Only included if provided
    await self._send_request(req_id, "chat.send", params)
```

Key pattern: model parameter is **optional** at every layer. When omitted, the server uses its configured default. When provided, it overrides.

---

## TypeScript Pattern: Config-Driven Provider Factory (Nexus)

### Provider factory with config snapshot caching

```typescript
const DEFAULT_MODEL = 'claude-haiku-4-5-20251001';

export function createAnthropicProvider(config: NexusConfig): LlmProvider {
  const model = config.anthropicModel ?? DEFAULT_MODEL;

  const client = new Anthropic({
    ...(auth.apiKey ? { apiKey: auth.apiKey } : {}),
    ...(auth.baseURL ? { baseURL: auth.baseURL } : {}),
  });

  return {
    name: 'anthropic',
    async chatCompletion(opts) {
      const message = await client.messages.create({
        model,  // Baked in at factory creation time
        max_tokens: opts.maxTokens,
        system: opts.system,
        messages: [{ role: 'user', content: opts.userMessage }],
      });
      return { text, usage, model };
    },
  };
}
```

### Multi-provider support via config

```typescript
export function createProvider(config: NexusConfig): LlmProvider {
  const providerType = config.llmProvider ?? 'anthropic';

  switch (providerType) {
    case 'openrouter':
      return createOpenRouterProvider(config);
    case 'anthropic':
      return createAnthropicProvider(config);
    case 'ollama':
      return createOllamaProvider(config);
  }
}
```

Key pattern: Provider is a **pluggable factory** driven by config. Model ID lives in config, not code. Default is always the cheapest viable option (Haiku).

---

## Common Principles

1. **Default cheap, upgrade explicitly** — Haiku or Flash as the default; Sonnet/Opus only where justified
2. **Always have a fallback** — primary fails → cheaper/different provider catches it
3. **Config over code** — model IDs in config files, not hardcoded strings
4. **Cost comments** — annotate model entries with pricing so developers understand tradeoffs
5. **Optional model overrides** — let callers override the default when needed, but don't require it
