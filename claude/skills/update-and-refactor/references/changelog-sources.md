# Finding what changed between two versions

Build-verify catches signature breaks. It does **not** catch changed defaults,
deprecations, runtime behavior, performance shifts, or new features — those only
live in human-written release notes. This pass fills that gap. Treat everything
here as *claims* (label them as changelog-sourced in the report), distinct from
the *verified* compiler evidence.

## Step 1 — Find the source repository

Get the project/repo URL from package metadata:

- **NuGet**: the `.nuspec` `projectUrl`/`repository`, or the package page on
  nuget.org (`https://www.nuget.org/packages/<id>`). Microsoft Learn MCP is
  authoritative for Microsoft/Azure packages.
- **npm**: `npm view <pkg> repository.url` and `npm view <pkg> homepage`.
- **PyPI**: `https://pypi.org/pypi/<dist>/json` → `info.project_urls`
  (Source / Homepage / Changelog).
- **Generic**: the manifest or registry metadata usually carries a repo link.

Many packages publish a `Changelog` URL directly in `project_urls` — prefer it.

## Step 2 — Get the changes between YOUR two versions specifically

You want the delta from installed → latest, not a generic "what's new". Best
sources, in order of usefulness:

1. **GitHub Releases between the two tags.** Use `gh`:
   ```bash
   gh release list --repo <owner/repo> --limit 50
   gh release view <tag> --repo <owner/repo>
   ```
   Read every release note from the version after `current` up to and including
   `latest` — breaking changes are sometimes introduced in an intermediate
   version, not just the latest. The GitHub MCP (Code Mode) is good for walking
   several releases in one flow.

2. **`CHANGELOG.md` in the repo**, read at the `latest` tag. Scope to the
   relevant version range.

3. **Migration / upgrade guides.** Major versions of serious libraries usually
   have a dedicated "Migrating from vN to vN+1" doc. WebSearch
   `"<package> migrate v<old> to v<new>"`. These are gold for fix suggestions.

4. **Compare view** for the gritty truth when notes are thin:
   `https://github.com/<owner/repo>/compare/<oldtag>...<newtag>` — diff of
   public API files, often more honest than the prose.

5. **Version-specific API docs** via Context7 (`resolve-library-id` →
   `query-docs`) to confirm a specific method's current signature when a
   changelog is vague.

## Step 3 — Extract what matters, tied to this project's usage

From the gathered notes, pull out only what's actionable for *this* project:

- **Breaking changes** that touch APIs the usage-map shows the project actually
  uses. A breaking change in an API the project never calls is a footnote, not a
  finding — mention briefly, don't alarm.
- **New features** relevant to what the project does with the library. Explain
  the "why it matters here", not just "this exists".
- **Behavioral / default changes** — the silent biters. Flag changed defaults,
  new required config, altered retry/timeout/serialization behavior.
- **Deprecations** — still works now, will break later. Worth a low-severity
  finding plus a forward-looking suggestion.

## Honesty rules for this pass

- If you can't find a changelog or repo, say so in the report ("no release notes
  located; breaking-change detection for this package relies on build-verify
  only"). Don't pad with guesses.
- Quote or closely paraphrase the source for each claim so the user can verify.
- When build-verify and the changelog disagree (e.g. notes say "no breaking
  changes" but the build fails), trust the build and note the discrepancy — it
  usually means an undocumented break.
