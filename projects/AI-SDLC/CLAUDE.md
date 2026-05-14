# AI-PDLC Platform Configuration

## Platform Overview

This is the **AI-PDLC Platform v4.0** - a tool-agnostic, multi-offering system for AI-powered product/process development.

**AI-PDLC** (AI Product Development Lifecycle) is a comprehensive methodology for building software in the age of AI. The platform provides:
- **Core primitives** - Reusable building blocks (agents, skills, artifacts, context patterns)
- **Meta-skills** - Shared capabilities (narrative enhancement, reporting, context operations)
- **Offerings** - Specific implementations (SDLC Framework, Agentic Transformation Assessment)

## Platform Architecture

```
AI-PDLC/
├── core/                           # SHARED across all offerings
│   ├── primitives/                 # Domain-agnostic building blocks
│   ├── skills/                     # Meta-skills (4 skills)
│   ├── reference/                  # Shared validation & tools
│   └── templates/                  # Standard templates
│
├── offerings/                      # OFFERING-SPECIFIC implementations
│   ├── sdlc-framework/             # AI-SDLC v3.8 (software development)
│   │   ├── agents/                 # 4 phase agents
│   │   ├── context/                # Context system
│   │   ├── projects/               # Project workspaces
│   │   └── reference/              # SDLC-specific references
│   │
│   └── agentic-transformation/     # Assessment offering (enterprise readiness)
│       ├── agents/                 # 3 assessment agents
│       ├── context/                # Assessment context
│       └── projects/               # Assessment projects
│
├── .claude/commands/               # Platform-aware commands
└── docs/                           # Platform & offering documentation
```

## Current Offerings

| Offering | Status | Agents | Skills | Purpose |
|----------|--------|--------|--------|---------|
| **sdlc-framework** | ✅ Active | 4 | 26 | AI-assisted software development lifecycle |
| **agentic-transformation** | 🚧 In Development | 3 | 8 | Enterprise AI agent readiness assessment |

See `OFFERINGS.md` for complete catalog.

## Key Directories

| Directory | Purpose | Status |
|-----------|---------|--------|
| `core/primitives/` | Domain-agnostic building blocks | **ACTIVE** |
| `core/skills/` | Meta-skills (narrative, reporting, context ops) | **ACTIVE** |
| `core/reference/validation/` | Shared validation rules | **ACTIVE** |
| `offerings/sdlc-framework/` | SDLC offering (former AI-SDLC v3.8) | **ACTIVE** |
| `offerings/agentic-transformation/` | Assessment offering | **IN DEVELOPMENT** |
| `.claude/commands/` | Platform-aware slash commands | **ACTIVE** |
| `docs/platform/` | Platform documentation | **ACTIVE** |
| `docs/offerings/` | Per-offering documentation | **ACTIVE** |

## IGNORE THESE DIRECTORIES

**DO NOT read, reference, or use content from these archived directories:**

- `archive/` - Contains deprecated v1 and v2 implementations
- `archive/sdlc-v1/` - Legacy v1 primitives-based architecture (Oct 2024)
- `archive/sdlc-v2/` - Legacy v2 skills-based architecture (Nov 2024)
- `archive/projects-v1/` - Legacy project files
- `.sdlc/` - Old structure (moved to `offerings/sdlc-framework/`)

These are kept for historical reference only. All current work uses v4.0 platform structure.

## Commands

### Platform Commands

Available slash commands in `.claude/commands/`:

| Command | Description | Offering |
|---------|-------------|----------|
| `/list-offerings` | List all available offerings | Platform |
| `/init-offering [offering] [project]` | Initialize project in any offering | Platform |

### SDLC Framework Commands

| Command | Description |
|---------|-------------|
| `/init-sdlc-v3 [project]` | Initialize SDLC project (alias for `/init-offering sdlc-framework`) |
| `/run-agent [agent] [project]` | Execute phase agent |
| `/run-agent-conversational [agent] [project]` | Execute agent in conversational coaching mode |
| `/run-skill [agent] [skill] [project]` | Execute individual skill |
| `/sdlc-status [project]` | Check project status |
| `/generate-dashboard [project]` | Generate interactive HTML dashboard |
| `/generate-docx [doc-type] [project]` | Generate professional Word documents |
| `/enhance-artifact [path] [project]` | Transform artifacts into narrative-rich versions |

See `.claude/commands/README.md` for detailed command documentation.

## Core Layer

### Meta-Skills (core/skills/)

**Shared across all offerings:**

| Skill | Purpose | Used By |
|-------|---------|---------|
| `context-operations` | Context file operations (read, update, validate) | All phase-completion skills |
| `narrative-enhancer` | **MANDATORY** - Transform artifacts to prose | All creation/analysis skills |
| `html-report-generator` | Generate interactive dashboards | SDLC, Assessment |
| `docx-artifact-generator` | Generate Word documents | All offerings |

### Primitives (core/primitives/)

**Domain-agnostic building blocks:**
- Agent patterns (`core/agent.md`)
- Skill patterns (`core/skill.md`)
- Artifact patterns (`core/artifact.md`)
- Context patterns (`core/context.md`)
- Orchestration patterns (`core/orchestration.md`)

**See:** `core/README.md` for complete core layer documentation

## SDLC Framework Offering (offerings/sdlc-framework/)

**Formerly:** AI-SDLC v3.8
**Current Location:** `offerings/sdlc-framework/`

### Architecture

- **4 Phase Agents** - Discovery, Specification, Planning, Implementation
- **26 Phase Skills** - Activities within each agent
- **Dual Output** - All creation skills produce standard + narrative versions
- **Context System** - Tiered context (foundation → layers → reference)
- **Quality Gates** - Five-gate validation system

### Phases

```
Phase 0: Discovery      → 6 skills  → GO/CONDITIONAL GO/NO-GO
Phase 1: Specification  → 7 skills  → GO/CONDITIONAL GO/NO-GO
Phase 2: Planning       → 7 skills  → GO/CONDITIONAL GO/NO-GO
Phase 3: Implementation → 6 skills  → Project complete
```

### Quick Start (SDLC Framework)

```bash
# Initialize SDLC project
/init-sdlc-v3 my-project

# Add input documents to:
# offerings/sdlc-framework/projects/my-project/inputs/raw/

# Run through phases
/run-agent phase0-discovery my-project
/run-agent phase1-specification my-project
/run-agent phase2-planning my-project
/run-agent phase3-implementation my-project
```

**See:** `offerings/sdlc-framework/README.md` for complete SDLC documentation

## Agentic Transformation Offering (offerings/agentic-transformation/)

**Status:** In Development
**Purpose:** Enterprise readiness assessment for AI agent adoption

### Architecture

- **3 Assessment Agents** - Ingestion, Analysis, Synthesis
- **8 Assessment Skills** - Data collection, readiness scoring, opportunity mapping, business case building
- **Primary Deliverable** - Interactive React dashboard with assessment findings

**See:** `offerings/agentic-transformation/README.md` for complete assessment documentation

## Quality Gates

All skills use **five-gate validation**:

| Gate | Name | Blocking? |
|------|------|-----------|
| Gate 0 | Artifact Integrity | **Yes** |
| Gate 1 | Completeness | **Yes** |
| Gate 2 | Arithmetic Verification | **Yes** |
| Gate 3 | Classification Verification | **Yes** |
| Gate 4 | Quality Assessment | No |

Phase validation produces: **GO / CONDITIONAL GO / NO-GO**

**See:** `core/reference/validation/validation-rules.reference.md`

## Dual Output System (MANDATORY)

All **creation** and **analysis** skills are **required** to produce two versions of each artifact:

| Version | Filename | Audience |
|---------|----------|----------|
| **Standard** | `artifact.md` | AI agents, technical review |
| **Narrative** | `artifact.narrative.md` | Stakeholders, executives, clients |

Narrative enhancement runs **automatically** after every creation/analysis skill completes.

**Reference:** `core/skills/narrative-enhancer/SKILL.md`

## Migration from AI-SDLC v3.8

**If you were using AI-SDLC v3.8:**

All content has been migrated to `offerings/sdlc-framework/`. Existing commands still work:

```bash
# These still work (backward compatible)
/init-sdlc-v3 my-project
/run-agent phase0-discovery my-project
/sdlc-status my-project
```

Your projects have been moved to:
```
.sdlc/projects/ → offerings/sdlc-framework/projects/
```

**See:** `.sdlc/README.md` for complete migration details

## Documentation Structure

| Document | Description |
|----------|-------------|
| `README.md` (root) | Platform overview and quick start |
| `OFFERINGS.md` (root) | Catalog of all available offerings |
| `core/README.md` | Core layer documentation |
| `offerings/sdlc-framework/README.md` | SDLC Framework offering |
| `offerings/agentic-transformation/README.md` | Assessment offering |
| `docs/platform/` | Platform architecture and patterns |
| `docs/offerings/` | Per-offering guides |

## Documentation Maintenance (IMPORTANT)

**When making changes to the platform**, always update these files:

| File | Update When... |
|------|----------------|
| `README.md` (root) | Platform architecture, version bumps, new offerings |
| `CLAUDE.md` (this file) | Directory structure, command changes, offering status |
| `OFFERINGS.md` | Adding/removing offerings, status changes |
| `core/README.md` | Adding core skills, primitives, references |
| `offerings/[name]/README.md` | Offering-specific changes |
| `.claude/commands/README.md` | Adding/modifying commands |

**Checklist for significant changes:**
- [ ] Update version number in `README.md` header
- [ ] Add changelog entry in `README.md`
- [ ] Update offering status in `OFFERINGS.md`
- [ ] Update directory tables in `CLAUDE.md`
- [ ] Document new commands in `.claude/commands/README.md`
- [ ] Update any affected offering READMEs

## Version History

| Version | Architecture | Date |
|---------|--------------|------|
| v1.0 | Primitives-based | Oct 2024 |
| v2.0 | Skills-based | Nov 2024 |
| v3.0-3.8 | Agentic (SDLC only) | Dec 2024 - Feb 2026 |
| **v4.0** | **Platform (multi-offering)** | **Feb 2026** |

**See:** `README.md` for complete changelog

---

**AI-PDLC Platform v4.0**
**Last Updated:** 2026-02-13
**Offerings:** 2 (1 active, 1 in development)
**Core Skills:** 4 meta-skills
**Total Agent Skills:** 34+ across all offerings

<!-- nexus:start -->
## Nexus Intelligence

*Auto-updated by Nexus — do not edit this section manually.*
*Last sync: 2026-03-24*

### Portfolio
| Project | Description | Tech |
|---------|------------|------|
| project-avatar | — | — |
| ComfyUI | **ComfyUI** — the main local ComfyUI installation at E:/ComfyUI-Easy-Install/Co… | — |
| sage-voice | **sage-voice** — MCKRUZ project for Sage's voice capabilities.

Sage is the AI … | — |
| openclaw-voice | **OpenClaw Voice** — Discord voice bot enabling AI agents (Jarvis and Sage) to … | — |
| matthewkruczek-ai | **matthewkruczek.ai** — static personal brand website for Matthew Kruczek (EY M… | — |
| claude-code-mastery | **Claude Code Mastery** — the definitive Claude Code setup and configuration sk… | — |
| ProjectPrism | **Prismcast / ProjectPrism** — autonomous AI news aggregation, synthesis, and v… | — |
| ComfyUI Expert | **VideoAgent / ComfyUI Expert** — session-scoped Claude Code orchestrator that … | — |
| ArchitectureHelper | **AzureCraft / ArchitectureHelper** — AI-native Azure infrastructure designer f… | — |
| **AI-SDLC** (this) | **AI-PDLC Platform** — multi-offering system for AI-assisted consulting and sof… | — |
| Nexus | Nexus is a local-first cross-project intelligence layer for Claude Code. | — |
| _+26 inactive_ | — | — |

### Context from project-avatar
#### Mac Mini SSH & Infrastructure
## Mac Mini (PRIMARY — Sage lives here)

- **Host:** 192.168.50.189
- **SSH:** `ssh matthewkruczek@192.168.50.189`
- **Platform:** Apple Silicon (arm…
*Tags: infrastructure, ssh, mac-mini, deployment, neo4j, docker*

> **Cross-project rule**: Before making decisions that affect shared concerns (APIs, auth, data formats, deployment) or asking the user for server/SSH/infrastructure details, run `nexus_query` to check for existing decisions, notes, and conflicts across the portfolio.

*[Nexus: run `nexus query` to search full knowledge base]*
<!-- nexus:end -->
