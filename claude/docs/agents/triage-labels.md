# Triage Labels

**Scope: global default.** Applies to every repo unless the repo has its own `docs/agents/triage-labels.md` — a repo-local file always wins.

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in the issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

A repo whose GitHub Issues already use different label names should get its own `docs/agents/triage-labels.md` with the right-hand column overridden, so `/triage` applies existing labels instead of creating duplicates.
