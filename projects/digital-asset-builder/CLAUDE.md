# Digital Asset Builder

## Stack
Python 3.12+, Typer (CLI), SQLite (state), httpx (async HTTP), Pydantic (models), Pillow (image QC), Anthropic SDK (LLM)

## Architecture
Automated pipeline: research → brief → generate (ComfyUI) → QC → package → publish → monitor.
Each stage is an independent, retryable step. Jobs persist in SQLite and survive crashes.
Config-driven: product types and marketplaces defined in config, not hardcoded.

## Code Style
- Immutable data: Pydantic `frozen=True` models, no mutation
- Type hints everywhere, strict mode Pydantic
- Async by default for I/O (httpx, ComfyUI API, marketplace APIs)
- Small focused modules: one file per pipeline stage, <400 lines
- Feature/domain organization, not layer-based

## Project Structure
```
src/dab/              # Main package ("digital asset builder")
  cli/                # Typer CLI commands
  pipeline/           # Pipeline stages (research, brief, generate, qc, package, publish, monitor)
  comfyui/            # ComfyUI API client and workflow management
  marketplaces/       # Marketplace integrations (etsy, itch, gumroad, creative_market)
  models/             # Pydantic models (jobs, products, configs)
  db/                 # SQLite repository layer
config/               # Product type configs, marketplace configs, workflow templates
tests/                # Mirrors src structure
```

## Commands
- `uv run dab` — Run CLI
- `uv run pytest` — Run tests
- `uv run ruff check src/` — Lint
- `uv run ruff format src/` — Format
- `uv run mypy src/` — Type check

## Verification
After changes: `uv run ruff check src/ && uv run mypy src/ && uv run pytest`

## Key Integrations
- **ComfyUI:** REST API at localhost:8188. Workflow JSON files in `config/workflows/`.
- **Etsy:** OAuth 2.0 API. Listings, images, digital downloads.
- **Itch.io:** butler CLI for uploads. API for listing management.
- **Claude API:** Research analysis, brief generation, SEO copy, quality descriptions.

## Task Approach
1. Each pipeline stage should work independently and be testable in isolation.
2. State machine pattern: jobs transition through stages with persisted state.
3. Failures retry with exponential backoff. Partial progress is saved.
4. New product types = new config file + optional workflow template. No core code changes.
5. New marketplaces = new module in `marketplaces/` implementing a common interface.

## Common Mistakes
- Don't hardcode product types or marketplace logic in pipeline stages
- Don't assume ComfyUI is always available — handle connection failures gracefully
- Don't store generated images in git — they go in `output/` (gitignored)
- Don't use sync HTTP calls — everything I/O-bound should be async
