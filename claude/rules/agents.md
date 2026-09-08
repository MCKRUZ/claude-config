# Agent Orchestration & Workflow

## Custom Subagents (`~/.claude/agents/matts-custom/`)

Four stack-tailored agents. Kept as agents because they benefit from subagent isolation and/or auto-spawn.

| Agent                | Purpose                 | When to Use                       |
| -------------------- | ----------------------- | --------------------------------- |
| planner              | Implementation planning | 5+ file features, new services    |
| architect            | System design           | Major architectural decisions     |
| security-reviewer    | Security analysis       | Auth/payment/identity code (auto) |
| build-error-resolver | Fix build errors        | When build fails (auto)           |

### Retired agents → use the command/skill instead

These were removed (archived to `MCKRUZ/claude-agents-archive`) because a maintained command or skill already covers them. Don't recreate them as agents.

| Capability           | Use instead                               |
| -------------------- | ----------------------------------------- |
| Code review          | `/code-review` (built-in, diff-aware)     |
| TDD                  | `tdd` skill + `rules/testing.md`          |
| E2E testing          | `e2e` skill (Playwright)                  |
| Dead-code / refactor | `code-simplifier` → `/simplify`           |
| Docs                 | `/update-docs`                            |

## When to Auto-Spawn Agents

Only mandatory without user prompt:

1. Security-sensitive code (auth, payments, identity) → **security-reviewer**
2. Build failure → **build-error-resolver**

Available on request or when clearly beneficial:

- Complex features → planner (suggest it, don't force it)
- After implementation → `/code-review` (command, for PRs — not every edit)
- TDD workflow → `tdd` skill (when you want TDD)

## Commit Messages

Format: `type: description` (feat, fix, refactor, docs, test, chore, perf, ci)

- Imperative mood, lowercase, no period at end
- Under 72 characters
- Body optional — explain "why" not "what" when included

## PR Workflow

1. Analyze full commit history with `git diff [base-branch]...HEAD`
2. Draft comprehensive summary with test plan
3. Push with `-u` flag if new branch
4. PR title under 70 characters — use description for details
