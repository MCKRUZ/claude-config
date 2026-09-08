# Development Workflow

## 5-Phase Pipeline

For non-trivial features (3+ files or unclear requirements), follow these phases in order.

### Phase 1: Research & Reuse
Before writing new code, search for existing solutions across **multiple sources**:
1. **Codebase first**: `grep`, `glob` for similar patterns already in the project
2. **GitHub**: `gh search repos` and `gh search code` for proven implementations; use the Bifrost GitHub Code Mode server for multi-step exploration (repo contents, issue context, PR discussions)
3. **Library docs**: Use Context7 (`resolve-library-id` then `query-docs`) for API specifics; use Microsoft Learn MCP for .NET/Azure APIs
4. **YouTube**: Use the YouTube MCP server to find conference talks, deep-dive tutorials, and framework walkthroughs — video content often has implementation details that docs miss
5. **Reddit**: Use the Bifrost Reddit Code Mode server to check community sentiment, gotchas, and real-world experience with libraries/patterns/approaches
6. **Web**: WebSearch for broader coverage — blog posts, Stack Overflow, official announcements
7. **Registry search**: npm, NuGet, PyPI before hand-rolling utilities

Research means casting a wide net. Don't stop at the first source that looks promising — cross-reference across at least 2-3 sources before committing to an approach. Only proceed to implementation after confirming no suitable solution exists.

### Phase 2: Plan
- Enter plan mode for 5+ file features
- Define the approach, files to touch, and order of changes
- Identify risks and unknowns upfront
- Get user alignment before writing code

### Phase 3: Implement (TDD when applicable)
- Write failing test first (for bug fixes: always; for features: when requested)
- Implement the minimum code to pass
- Refactor while tests stay green

### Phase 4: Verify
- Check, in order: build, types, lint, tests, security, diff
- 80% coverage minimum on new code
- No console.log, no hardcoded secrets, no TODO comments

### Phase 5: Commit & Review
- Stage specific files (not `git add -A`)
- Commit message: `type: description` (imperative mood, under 72 chars)
- For PRs: full commit history analysis, comprehensive description

## Research-First Rule

**This is mandatory, not optional.** When implementing something new:
- Spend 2-5 minutes researching before writing any code
- Check if someone has already solved this problem (in this codebase or externally)
- Verify API signatures and framework behavior against docs, not memory
- Prefer adapting a proven 80% solution over building from scratch

## 3-Strike Research Escalation

If an implementation approach fails 3 consecutive times with different attempts, **stop guessing and escalate to external research**:

1. Use Context7, Microsoft Learn, or web search to find current best practices
2. Search YouTube (MCP) for recent conference talks or tutorials covering the topic
3. Search Reddit (Bifrost Code Mode) and GitHub issues for known gotchas or workarounds
4. Check for known issues, breaking changes, or version-specific behavior
5. Document what you found before attempting the next fix

This applies to: build errors, test failures, API integration issues, config problems — any situation where repeated attempts aren't converging on a solution. The goal is to break out of local-knowledge loops before burning context on a fourth guess.
