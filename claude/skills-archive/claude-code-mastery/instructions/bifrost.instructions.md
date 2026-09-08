# Bifrost MCP Gateway

Bifrost (`http://matthews-mac-mini.tail2800e3.ts.net:8090/mcp`) proxies multiple MCP servers behind one endpoint. Some servers expose tools directly ("Classic"); others run in "Code Mode" and are hidden behind a meta-tool dance. Reach for these servers **proactively** when a task matches the unique value below — don't wait to be asked.

## Tool selection priority

When a task could be done multiple ways, pick in this order:

1. **Built-in tools** (WebSearch, WebFetch, Bash, Read, Grep, Edit) — zero friction, use when they cleanly satisfy the task.
2. **`gh` CLI via Bash** for single-shot GitHub reads (view PR, list issues).
3. **Bifrost Classic-mode servers** when a specialist tool adds clear value.
4. **Bifrost Code Mode servers** when the unique capability is genuinely needed.

Don't reach for Bifrost just because it exists. Reach when the specialist capability beats what a built-in can do.

---

## Classic Mode — tools visible directly in your tool list

These appear as normal MCP tools. Use them when their **unique value** matches the task.

### context7 — version-specific library API reference
**Unique value:** up-to-date, version-specific API signatures and code examples for third-party libraries. Authoritative for exact method/config/flag details that your training data may have wrong.
**Reach when:** verifying a specific method signature, config option, or version-specific behavior in React, Angular, xUnit, FluentValidation, MediatR, or any third-party library. Not for general concept explanations.
**Flow:** `resolve-library-id` → `query-docs`.

### sequential_thinking — structured multi-step reasoning
**Unique value:** forces explicit branching, revision, and hypothesis-testing on hard problems where the path isn't clear. Not for routine work — the overhead isn't worth it.
**Reach when:** weighing architectural trade-offs, debugging non-obvious issues whose root cause is unclear, or planning multi-file implementations across 3+ files.

### microsoft_learn — authoritative Microsoft docs
**Unique value:** official Microsoft/Azure/.NET documentation — more reliable than general web search for Microsoft APIs, and current.
**Reach when:** working on .NET, ASP.NET Core, EF Core, Azure SDK, Bicep, ARM schema, or M365 code. Verifying an SDK method, Azure CLI flag, or ARM/Bicep property. Finding official Microsoft code samples.

### YouTube — programmatic video data
**Unique value:** transcripts, statistics, comments, channel data for YouTube content — things no scraper or web search gets cleanly.
**Reach when:** user references a specific video/channel, or the best technical content on a topic exists primarily in video form (conference talks, framework walkthroughs, deep-dive tutorials).

---

## Code Mode — 4 meta-tools in your list, actual servers hidden

You will only see `listToolFiles`, `readToolFile`, `getToolDocs`, `executeToolCode` in your direct tool list. The servers below are reachable through them. **Invocation pattern:**

1. `listToolFiles` — tree of available Code Mode servers
2. `readToolFile` with the server — compact Python `.pyi` stubs showing tool signatures
3. `executeToolCode` — run Python in a Starlark sandbox that calls the tool(s)

Batch related calls into one `executeToolCode` script when possible — fewer round-trips.

### github (Code Mode) — orchestrated GitHub workflows
**Unique value:** multi-step GitHub operations that would be awkward as a chain of `gh` CLI calls — creating a branch + writing files + opening a PR + adding reviewers in one flow, or when you need structured data back rather than parsing CLI output.
**Reach when:** orchestrating multiple GitHub actions in sequence. For single reads (view PR, list issues, check status), use `gh` CLI — it's faster and already in your toolbelt.

### firecrawl (Code Mode) — content that WebSearch/WebFetch can't reach
**Unique value:** JS-rendered pages, auth-walled content, structured extraction with a JSON schema, whole-site crawling, URL mapping, autonomous open-ended research.
**Reach when:**
- Page requires JavaScript to render (SPAs, dashboards, anything where curl returns an empty shell)
- Structured extraction needed with a defined schema (`firecrawl_extract`)
- Crawling an entire site or mapping URL structure (`firecrawl_crawl`, `firecrawl_map`)
- Open-ended "research X on the web" tasks (`firecrawl_agent`)

Do NOT reach for firecrawl on a simple web search — built-in `WebSearch` is lighter and wins.

### playwright (Code Mode) — real browser automation with state
**Unique value:** driving a live Chromium instance — filling forms, clicking through flows, waiting for dynamic content, taking interactive screenshots of flows.
**Reach when:** the task requires *doing* something in a browser, not just reading one page. UI testing, automating a multi-step user flow, reproducing a browser-state bug.

For read-only page inspection with an already-running Chrome session, `chrome_devtools` is lighter.

### chrome_devtools (Code Mode) — lightweight CDP inspection
**Unique value:** attach to an already-running Chrome instance via CDP to evaluate JavaScript, navigate, or screenshot — without spinning up a full Playwright automation stack.
**Reach when:** quick debugging of a live page where a browser session already exists. For fresh browser automation, use playwright.

### Reddit (Code Mode) — community sentiment and thread context
**Unique value:** real user opinions with full thread/comment context — something general web search flattens or misses entirely.
**Reach when:** the task is "what do people actually think of X," "is there existing community discussion of Y," or the user references a specific subreddit or Reddit post.

---

## Adding a new MCP server

- **Classic mode:** no update to this file needed — tools show up in your list with their own descriptions.
- **Code Mode:** add a short entry to the Code Mode section describing the server's unique value and when to reach for it, otherwise the model won't know to dance through `listToolFiles`.

## Meta-tool usage

`listToolFiles` / `readToolFile` / `getToolDocs` / `executeToolCode` are for the Code Mode flow above. Call them proactively when a task matches a Code Mode server's unique value. Also call them reactively when a tool call fails and you need to verify a signature, or when the user explicitly asks what's connected.
