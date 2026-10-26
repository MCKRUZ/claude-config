# Report, findings schema, and plan format

## Contents

- findings.json — the contract with the renderer
- The report
- Plan documents

## findings.json — the contract with the renderer

Write this to `.update-and-refactor/findings.json`. The renderer
(`scripts/render_report.py`) consumes exactly this shape. Keep evidence labeled
so the report can show the user what's verified vs. claimed.

```json
{
  "project": "MyApi",
  "generated": "2026-06-26",
  "summary": "Analyzed 3 packages. 1 safe minor bump, 2 with breaking changes.",
  "packages": [
    {
      "name": "Azure.AI.Agents.Persistent",
      "ecosystem": "nuget",
      "current": "1.0.0",
      "latest": "2.1.0",
      "jump": "major",
      "repo_url": "https://github.com/Azure/azure-sdk-for-net",
      "verdict": "2 breaking changes — plan before upgrading",
      "build_verified": true,
      "usage": [
        { "file": "src/Agents/Runner.cs", "line": 42, "snippet": "var client = new PersistentAgentsClient(endpoint, cred);" }
      ],
      "breaking_changes": [
        {
          "title": "PersistentAgentsClient constructor now requires AgentsClientOptions",
          "severity": "high",
          "evidence_type": "compiler",
          "evidence": "CS1501: No overload for 'PersistentAgentsClient' takes 2 arguments",
          "affected_usage": ["src/Agents/Runner.cs:42"],
          "fix_suggestion": "Pass an AgentsClientOptions; default options preserve current behavior: new PersistentAgentsClient(endpoint, cred, new AgentsClientOptions())"
        }
      ],
      "new_features": [
        {
          "title": "Built-in streaming responses",
          "added_in": "2.0.0",
          "description": "A new GetResponseStreamingAsync method returns an IAsyncEnumerable of partial response chunks as the agent generates them, instead of one blocking call that returns only when the full response is ready.",
          "benefit": "Tokens surface to the caller as they're produced — lower time-to-first-token, and you can render or forward output incrementally instead of waiting for the whole completion.",
          "example": "await foreach (var chunk in client.GetResponseStreamingAsync(request))\n    Console.Write(chunk.Text);",
          "relevance": "Runner.cs:55-70 currently polls GetResponse in a loop with a 500ms sleep. Streaming removes the poll loop entirely and cuts perceived latency for the chat UI this feeds.",
          "suggestion": "Replace the poll loop in Runner.cs:55-70 with an await-foreach over GetResponseStreamingAsync; forward each chunk to the existing IProgress sink.",
          "docs_url": "https://learn.microsoft.com/dotnet/api/azure.ai.agents.persistent"
        }
      ],
      "behavioral_notes": [
        {
          "title": "Default retry count changed 3 → 5",
          "evidence_type": "changelog",
          "evidence": "Release notes v2.0.0: 'default retries increased to 5'",
          "impact": "Slower failure surfacing on dead endpoints; override via options if undesired."
        }
      ]
    }
  ]
}
```

Field rules:
- `verdict`: the one-line decision, written in **plain language for a reviewer who
  may not be a day-to-day developer**. Lead with the call ("Safe to update",
  "Update, but plan it", "Don't update yet") and say why in business/impact terms.
  Keep the jargon (API names, error codes) for the evidence fields below, not the
  verdict. The verdict is the line a busy reader scans; make it stand on its own.
- `jump`: `"major" | "minor" | "patch"`.
- `severity`: `"high" | "medium" | "low"`.
- `evidence_type`: `"compiler" | "changelog" | "inference"` — this drives the
  badge that tells the user how much to trust the finding. Never mark something
  `compiler` unless an actual build produced it.
- `applies` (optional boolean): does this change actually break THIS project's
  code? The report separates breaks that affect the user from ones that are
  documented in the release but don't apply, so a "safe to update" verdict never
  sits above a scary "Breaking changes (4)" count. If you omit it, the report
  infers: compiler-verified breaks apply; on a build-verified package an
  unflagged changelog claim that didn't surface in the build is treated as not
  applicable (if it broke the code, the build would have failed). Set it
  explicitly to `true` for a genuine non-compile break that still applies — e.g.
  a new license requirement, or a removed API you use on a package that wasn't
  build-verified — and to `false` to force a documented-but-irrelevant change
  into the "doesn't affect you" group. Behavioral/runtime changes belong in
  `behavioral_notes`, not here.
- `build_verified`: did a trial build run for this package? If false (e.g.
  Python, or build wouldn't run), the report shows a "not build-verified" notice.
- Any array may be empty. A package with no breaking changes and a clean build is
  a valid, reassuring finding — give it a `verdict` like "Safe minor bump".
- For an unused outdated package: empty `usage`, and a `verdict` like "Not used
  in code — removal candidate".

## The report

Generate with the script, never by hand:

```bash
python update-and-refactor/scripts/render_report.py \
  .update-and-refactor/findings.json -o .update-and-refactor/report.html
```

What the rendered report gives the user (the script handles all of this — you
just supply good `findings.json` data):

- A top summary line + a per-package verdict table so the whole picture is
  scannable in five seconds.
- One collapsible card per package: current→latest with a colored jump badge,
  build-verified status, then breaking changes (severity + evidence-type badges,
  affected files, fix suggestion), new features (with the "why it matters here"),
  and behavioral notes.
- Evidence badges visually separate `compiler` (verified) from `changelog`
  (claimed) from `inference` (guessed) — this is the honesty surface, so the
  quality of your `evidence`/`evidence_type` values is what makes the report
  trustworthy.

Open it (`start .update-and-refactor/report.html` on Windows), tell the user it's
open, and stop for review.

## Plan documents

When the user picks items to plan, write one markdown file per item to
`.update-and-refactor/plans/`, named
`<package>__<breaking|feature>__<slug>.md`. A plan is a self-contained work order
someone could hand to a fresh agent. Use this structure:

```markdown
# Plan: <short title>

- **Package**: <name> <current> → <latest>
- **Type**: Breaking change | New feature
- **Severity / Value**: <high|medium|low> | <why worth doing>
- **Source finding**: <evidence_type> — <evidence, quoted>

## Apply gate
To execute this plan, tell the skill: "apply the plan <this filename>".
Applying it will: edit the files below, bump <package> to <latest> in <manifest>,
and verify with build + tests. Nothing happens until you ask.

## Affected files
- `src/Agents/Runner.cs:42` — <what changes>

## Change steps
1. <ordered, concrete steps — follow the project's coding + testing rules>
2. ...

## Verification
- [ ] <test that proves the change> passes
- [ ] `dotnet build` (or project build) is green
- [ ] Full test suite passes
```

Keep plans grounded in the actual usage sites and the project's own conventions
(its testing rules, immutability/style rules). For breaking-change plans, prefer
writing a failing test that reproduces the break first where feasible, per the
project's bug-fix workflow.

Generating a plan does **not** apply it. Applying is Phase 6, one plan at a time,
only on explicit request.
