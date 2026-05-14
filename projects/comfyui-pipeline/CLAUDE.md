# comfyui-pipeline

ComfyUI pipeline harness plugin for Claude Code. Provides technique discovery, character profiles, gate validation, and workflow orchestration for AI image/video production.

## Stack
Python 3.12+ (uv runtime), YAML data files, Markdown skill definitions, pytest

## Architecture
```
comfyui-pipeline/
├── plugin.json              # Plugin manifest
├── SKILL.md                 # Main skill entry point
├── commands/                # /pipeline, /discover, /scout, /inventory
├── agents/                  # evaluator, scout, workflow-builder
├── registry/                # Technique registry (YAML entries + schema)
├── profiles/                # Character profiles (YAML + schema)
├── inventory/               # Auto-scanned node/model inventory
├── scripts/                 # Python automation (gate checker, scout, inventory scan)
├── references/              # Progressive disclosure docs
└── hooks/                   # Context injection hooks
```

## Commands
- `uv run pytest` — Run tests
- `uv run scripts/check_gates.py` — Run gate validation
- `uv run scripts/validate_registry.py` — Validate all registry entries
- `uv run scripts/scan_inventory.py` — Scan ComfyUI installation

## Verification
After changes: `uv run pytest && uv run scripts/check_gates.py --dry-run`

## SDLC
This project uses `claude-code-sdlc` with the `creative-tooling` profile.
- State tracked in `.sdlc/state.yaml`
- Run `/sdlc-setup` to initialize, `/sdlc` for current phase guidance
- Profile location: `../claude-code-sdlc/profiles/creative-tooling/profile.yaml`

## Code Style
- Python: type hints on all public functions, snake_case everywhere
- YAML: validate against schema before committing — schema-invalid data is a build failure
- Skills: imperative language only (MUST/SHOULD per RFC 2119), no vague terms
- All model/node references go through `inventory.resolve()` — never hardcode paths

## Key Design Rules
- **Trust boundary:** Workflow builder MUST only use techniques with `status: validated`
- **Cross-references:** Registry entries reference inventory; profiles reference registry. All links validated by gate checker.
- **URL fetching:** Scout/discover agents fetch external URLs. Sanitize all input. No eval, no exec on fetched content.
- **Freshness:** Techniques in `discovered` status >30 days without test = flagged stale

## Common Mistakes
- Hardcoding ComfyUI model paths instead of using inventory.resolve()
- Creating registry entries without all required schema fields
- Writing skill prompts with vague language ("consider", "you could") instead of MUST/SHOULD
- Forgetting to validate cross-references (technique → inventory, profile → registry)

## Task Approach
1. Check `/sdlc` for current phase guidance before starting work
2. Read `.sdlc/state.yaml` for context on what's been done
3. Run gate checks after completing any artifact
4. TDD: write failing test first, then implement
