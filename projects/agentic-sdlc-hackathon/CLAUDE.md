# Agentic SDLC Hackathon

## Overview
A full-day, instructor-led workshop teaching developers the fundamentals of agentic software development. Tool-agnostic core curriculum with tool-specific lab tracks (starting with Claude Code).

**Duration:** 7 hours (9:00 AM – 4:00 PM)  
**Audience:** Developers — any stack, beginner to AI agentic tools  
**Max Participants:** 100 (individual work)  
**Format:** Alternating presentation + hands-on labs

## Quick Start

```bash
# View workshop structure
cat workshop.yaml

# Build participant workbook (PDF)
python tools/build_workbook.py

# Build facilitator guide
python tools/build_facilitator_guide.py
```

## Project Structure

```
agentic-sdlc-hackathon/
├── workshop.yaml               # Master config — modules, labs, timing
├── content/
│   ├── modules/                # Presenter scripts + slide content (m01–m07)
│   ├── labs/                   # Lab instructions (lab-01–lab-05)
│   ├── facilitator/            # Facilitator guide, timing, troubleshooting
│   └── demos/                  # Demo scripts and assets
├── participant/
│   ├── workbook/               # Participant workbook (printed + digital)
│   └── reference-cards/        # Quick-reference cheat sheets
├── sample-project/             # Instructor demo app (DevBoard)
├── tracks/
│   ├── claude-code/            # Claude Code-specific lab variants + setup
│   ├── cursor/                 # Cursor-specific (future)
│   └── factory-ai/             # Factory.ai-specific (future)
├── templates/                  # Content templates per type
├── references/                 # Source materials, guidelines
└── tools/                      # Build automation scripts
```

## Content Pipeline

```
outline → script → slides → demo → facilitator-guide → participant-workbook → validate
```

Use `/workshop-module` to draft a new module, `/workshop-lab` to draft a new lab.

## Module Map

| ID  | Title                        | Duration | Has Lab |
|-----|------------------------------|----------|---------|
| M01 | The Agentic Mental Shift     | 30 min   | No      |
| M02 | OOB Tool Usage               | 30 min   | Yes (LAB-01) |
| M03 | Project Context Files        | 20 min   | Yes (LAB-02) |
| M04 | Skills & Custom Commands     | 40 min   | Yes (LAB-03) |
| M05 | MCP Servers                  | 30 min   | Yes (LAB-04) |
| M06 | Token Management & Context   | 15 min   | No      |
| M07 | Agentic SDLC & Wrap-up       | 15 min   | No      |

## Naming Conventions

- Modules: `m##-kebab-title` (e.g., `m01-agentic-mental-shift`)
- Labs: `lab-##-kebab-title` (e.g., `lab-01-first-interaction`)
- Files: `m##-script.md`, `m##-slides.md`, `lab-##-instructions.md`
- Track overrides: `tracks/{tool}/lab-##-{tool}.md`

## Conventions

- All narration/script copy goes through `/humanizer` before final use
- No em-dashes in any written content — use commas or restructure
- Slide decks generated from markdown (see `templates/slides.md`)
- Lab instructions must have both a "What you'll do" summary and step-by-step body
- Every lab must have a "Done?" checklist at the end
