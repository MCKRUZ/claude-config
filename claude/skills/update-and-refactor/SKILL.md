---
name: update-and-refactor
description: >-
  Audits a project's third-party dependencies for newer releases, then for the
  packages the user selects, finds every place they're used, determines what
  actually changed between the installed and latest version (breaking changes,
  new features, behavioral changes), and produces a readable HTML report.
  After review, generates per-item refactor plans and can apply them one at a
  time on opt-in. Supports NuGet (.NET), npm (Node/Angular), PyPI (Python), and
  a generic fallback for other ecosystems. Use this skill whenever the user asks
  to "update and refactor", check for outdated/old dependencies, review package
  upgrades, find breaking changes from a library bump, modernize dependencies,
  or asks what would break if they upgraded a NuGet/npm/pip package. Trigger it
  even when the user names a single library (e.g. "is our Azure.AI.Agents
  package out of date and what breaks if I update it?") rather than saying
  "update and refactor" verbatim.
---

# Update and Refactor

Upgrading a dependency is a research problem before it's a coding problem. The
risk isn't the version bump — it's the breaking changes you didn't know about
and the new capabilities you didn't notice. This skill front-loads that research
into one reviewable report, then turns the user's decisions into concrete plans
and, on request, executes them.

The cardinal rule: **be honest about what is verified versus guessed.** A
compiler error is ground truth. A changelog line is a claim. A "this might
affect you" is an inference. Label them differently in everything you produce —
the user is trusting this report to decide what to touch in working code.

## When this runs

Trigger on explicit asks ("update and refactor", "check outdated deps", "what
breaks if I upgrade X") and on implicit ones where the user wants to understand
the gap between installed and latest versions of their libraries. It operates on
the project in the current working directory.

## The pipeline

Six phases. Phases 1–4 are read-only and always run end to end. Phases 5–6
happen only after the user reviews the report and opts in. Never skip ahead to
editing source before the report has been seen.

```
1 Detect      → find dependency manifests, identify ecosystems present
2 Inventory   → list outdated DIRECT deps; user picks which to deep-analyze
3 Analyze     → per chosen package: find usage + determine what changed
4 Report      → render one combined HTML report; STOP for user review
5 Plan        → for items the user picks, write a refactor plan doc each
6 Apply       → on per-plan opt-in, execute the refactor + verify the build
```

### Phase 1 — Detect

Find every dependency manifest in the project and determine which ecosystems are
in play. A repo may have several (a .NET API + an Angular front end is common).
Detection cues:

- **NuGet** — `*.csproj`, `Directory.Packages.props`, `packages.config`
- **npm** — `package.json`
- **PyPI** — `requirements*.txt`, `pyproject.toml`, `Pipfile`, `setup.py`
- **Anything else** — `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `composer.json`, etc.

Read the matching ecosystem reference file before acting — each has its own
tooling, its own way of mapping a package to the code that imports it, and its
own build-verify step:

- `references/nuget.md`
- `references/npm.md`
- `references/pypi.md`
- `references/generic.md` (use for any ecosystem without a dedicated file)

### Phase 2 — Inventory outdated direct dependencies

Per ecosystem, list **direct** dependencies (the ones the project explicitly
references — not transitive ones pulled in underneath them) that have a newer
**stable** release. Use the native tooling documented in each reference
(`dotnet list package --outdated`, `npm outdated`, `pip list --outdated`).

"Latest" means latest stable. Only consider prereleases if the project is
already on a prerelease of that package — otherwise you'd be pushing the user
onto unreleased code they didn't ask for.

Present the inventory as a compact table and let the user choose which packages
to deep-analyze. This selection gate exists because the expensive work
(usage-finding, trial builds, changelog fetching) shouldn't run across 40
packages when the user cares about 3. Group the table by jump size so big jumps
stand out:

```
| Package                      | Current | Latest | Jump  | Direct |
|------------------------------|---------|--------|-------|--------|
| Azure.AI.Agents.Persistent   | 1.0.0   | 2.1.0  | MAJOR | yes    |
| FluentValidation             | 11.9.0  | 11.11  | minor | yes    |
```

Then ask plainly: "Which of these should I dig into?" Accept "all", a subset, or
"just the majors". Do not proceed to Phase 3 until the user has chosen.

### Phase 3 — Analyze each selected package

For each chosen package, produce three things: where it's used, what changed,
and what that means for this project specifically.

**3a. Find usage.** Locate every place the project touches this package — imports
and the actual API calls, not just the import line. The how differs per
ecosystem (npm import specifier maps 1:1 to the package; NuGet packages expose
namespaces that don't always match the package name; Python import names can
differ from the distribution name) — follow the reference file. Record file +
line + a short snippet for each hit. If a package shows zero usage, say so
prominently in the report — an unused outdated dependency is a candidate for
removal, which is its own kind of useful finding.

**3b. Determine what changed — two independent sources, kept distinct.**

1. **Build-verify (ground truth for compile breaks).** For compiled or
   type-checked ecosystems, trial-bump the version in a throwaway copy of the
   project and build it. Real compiler/type errors are the most reliable
   breaking-change signal there is — they can't be missed or hallucinated. Each
   reference file documents its build-verify procedure and which errors map to
   API breaks. For interpreted ecosystems with no compile step, lean on the
   changelog and, where a fast test suite exists, a trial test run.

2. **Changelog / release notes (claims about behavior).** Build errors only
   catch signature-level breaks. Runtime behavior changes, default changes,
   deprecations, and — critically — *new features* live in the release notes.
   Read `references/changelog-sources.md` for how to find the source repo from
   package metadata and fetch what changed between the two specific versions.

   Use available research tools well: `gh` CLI or the GitHub MCP for releases
   and compare views, Context7 / Microsoft Learn MCP for version-specific API
   docs, WebSearch/WebFetch for migration guides. Cross-reference — a single
   changelog is often incomplete.

**3c. Classify and tailor.** Turn the raw findings into:

- **Breaking changes** — each with a severity, the evidence (label it: compiler
  error `CS0234` vs. changelog quote vs. inference), the specific usage sites it
  affects, and a concrete fix suggestion grounded in how this project uses the
  API.
- **New features** — not a feature dump, and not one-liners. Filter to features
  relevant *given what this project does with the library*, then make each one
  genuinely understandable. For every feature include: what it actually is and
  how it works (`description`), the concrete payoff (`benefit`), a short code
  snippet showing what using it looks like (`example`), why it matters for *this*
  project tied to a real usage site (`relevance`), how to adopt it
  (`suggestion`), the version it landed in (`added_in`), and a docs link
  (`docs_url`). The user is deciding whether a feature is worth adopting — give
  them enough to decide without leaving the report. A new retry policy matters if
  the project makes flaky network calls; skip it otherwise.
- **Behavioral notes** — changes that won't surface as compile errors but could
  bite at runtime (changed defaults, deprecations, perf characteristics).

Write all of this to `.update-and-refactor/findings.json` (schema and the exact
shape the report renderer expects are in `references/report-and-plans.md`).

### Phase 4 — Report and stop

Render one combined HTML report for the whole project, with a collapsible
section per analyzed package. Generate it with the bundled script — do not
hand-write HTML:

```bash
python update-and-refactor/scripts/render_report.py \
  .update-and-refactor/findings.json \
  -o .update-and-refactor/report.html
```

Open it for the user (`start` on Windows). The report's job is to be *scannable*:
severity badges, breaking changes up top, new features clearly separated, a
one-line verdict per package (e.g. "Safe minor bump" vs. "3 breaking changes,
plan before upgrading"). Detail is in `references/report-and-plans.md`.

Then **stop and hand control back.** Tell the user the report is open and that
once they've reviewed it, they can pick which breaking changes and features they
want plans for. Do not start writing plans unprompted.

### Phase 5 — Generate plans (on user selection)

When the user picks items, write one markdown plan per item to
`.update-and-refactor/plans/`. A plan is a self-contained, TDD-oriented work
order: the goal, the affected files, the version bump it requires, the
step-by-step change, and a verification checklist. Each plan opens with an
**Apply gate** the user can invoke to execute just that plan. Format spec is in
`references/report-and-plans.md`.

Plans are the default stopping point. Generating a plan does not apply it.

### Phase 6 — Apply (opt-in, one plan at a time)

Only when the user explicitly asks to apply a specific plan. Execute it
following the project's own conventions (see the user's testing and coding
rules): for a fix to a breaking change, write a failing test that reproduces the
break first where feasible, make the change, bump the package version in the
manifest, then verify — build, types, tests — and report what passed. Apply one
plan at a time and re-verify between them; a multi-package upgrade applied in one
shot is how you get a tangle of failures you can't bisect.

If the build was green before and isn't after, surface that immediately with the
actual error rather than pressing on.

## Operating notes

- **Read-only until Phase 5.** Phases 1–4 must never modify the user's source,
  manifests, or lockfiles. Do trial builds in a copy (use the scratchpad), never
  in place.
- **Honesty over confidence.** If you couldn't find a changelog, or the build
  wouldn't run, or you're inferring rather than verifying — say so in the report.
  A gap the user knows about is fine; a gap dressed up as a finding is harmful.
- **Output lives in `.update-and-refactor/`** at the project root: `findings.json`,
  `report.html`, and `plans/`. Suggest adding it to `.gitignore` if the project
  has one.
