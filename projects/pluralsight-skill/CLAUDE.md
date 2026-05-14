# Pluralsight Skill — Claude Code Skill for Content Creation

## What This Is
A Claude Code skill that helps create, structure, and refine Pluralsight course content — modules, clips, assessments, and skill IQ questions.

## Project Structure
```
SKILL.md              — Skill definition (loaded by Claude Code on invocation)
references/           — Pluralsight guidelines, formatting specs, example content
scripts/              — Helper scripts for validation, formatting, export
templates/            — Reusable templates for modules, clips, assessments
.claude/rules/        — Path-scoped Claude Code rules for this project
```

## Skill Development Conventions
- SKILL.md is the primary artifact. Keep it under 5,000 tokens — Claude Code wraps it in a system reminder and selectively ignores bloated instructions.
- Every instruction in SKILL.md must be actionable and universally applicable to skill invocations. Task-specific logic goes in templates or reference files.
- Use `references/` for content Pluralsight requires (formatting guidelines, rubrics, examples). SKILL.md should point to these, not inline them.
- Templates use `{{placeholder}}` syntax for variable content.

## Commands
- `git diff` — Review changes before committing

## Verification
Before committing: review SKILL.md for token bloat and ensure all referenced files exist.

## Common Mistakes
- Inlining Pluralsight formatting rules directly in SKILL.md instead of referencing `references/`
- Creating templates without placeholder documentation
- Forgetting to test the skill by actually invoking it with `/pluralsight-skill` in another project

# SDLC Configuration (auto-injected by /sdlc-setup)

## SDLC Plugin Active
This project uses the claude-code-sdlc plugin for lifecycle management.
- State: `.sdlc/state.yaml`
- Profile: `creative-tooling`
- Commands: `/sdlc`, `/sdlc-setup`, `/sdlc-status`, `/sdlc-next`, `/sdlc-gate`

## Stack: Creative Tooling
- **Language:** Python / uv-scripts / pytest
- **Primary Artifacts:** SKILL.md, templates, reference docs

## Quality Standards
- Code coverage: minimum 80%
- Max file size: 400 lines, max function: 50 lines
- TDD required: write tests first
- Code review required before merge
- Security review required for auth/sensitive code
- Skill prompt clarity: imperative instructions, no vague language, explicit defaults

## Coding Conventions
- Commits: `type: description` (feat, fix, refactor, docs, test, chore)
- Branches: `type/description`
- No debug artifacts in skill files

## Phase Awareness
Before making changes, check the current SDLC phase with `/sdlc`:
- During Implementation (Phase 4): follow section plans, use TDD
- During Quality (Phase 5): focus on review findings, not new features
- During Testing (Phase 6): fill coverage gaps, don't change architecture
