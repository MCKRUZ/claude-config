# Claude Code Sidecar

## Stack
TypeScript, Next.js 15 (App Router), React 19, Tailwind CSS v4, shadcn/ui, Tauri 2 (Rust backend), WebSocket (ws), chokidar (file watching)

## Architecture
Monorepo with three packages:
- `packages/core/` — Shared business logic: Claude Code subprocess manager, stream-json parser, session manager, file watcher
- `packages/web/` — Next.js app: chat UI + live preview iframe, WebSocket server for streaming events
- `packages/desktop/` — Tauri app: wraps the same React frontend with native Rust backend for subprocess + file watching

The core package is framework-agnostic TypeScript. Both web and desktop import from it.

## What This Project Does
Wraps Claude Code's headless mode (`claude -p "task" --output-format stream-json`) in a chat UI with a live preview pane. User types natural language, Claude Code edits files, preview refreshes automatically via file watcher.

## Key Concepts
- **Stream-JSON events**: Claude Code emits newline-delimited JSON (init, system, assistant, tool_result, result). The core parser transforms these into UI-friendly chat events.
- **Session persistence**: Each conversation tracks a session ID. Subsequent messages use `--resume <id>` to maintain context.
- **File watcher**: Monitors the target project directory. On file change, triggers preview pane reload via WebSocket message.
- **Sidecar config**: Each target project provides a small config (project dir, port, start command, ignore patterns).

## Code Style
- Strict TypeScript (`strict: true`). No `any` types.
- Immutable patterns: spread operators, never mutate objects/arrays.
- Functional React components with hooks only.
- kebab-case file names, PascalCase types/components, camelCase variables/functions.
- Zod for runtime validation of config and stream events.

## Commands
- `pnpm dev` — Start web dev server
- `pnpm build` — Build all packages
- `pnpm test` — Run tests (Vitest)
- `pnpm lint` — ESLint
- `npx tsc --noEmit` — Type check all packages
- `pnpm tauri dev` — Start Tauri desktop app (from packages/desktop)

## Verification
After changes: `pnpm build && pnpm test`

## Important Boundaries
- The sidecar app NEVER manages Claude Code auth. It reuses existing credentials on the machine.
- The sidecar app does NOT edit files itself. Only Claude Code (the subprocess) edits files.
- The preview pane is an iframe pointing at localhost — the target app must be running separately.
- This is a template/toolkit, not an opinionated application. Keep it minimal and configurable.

## Common Mistakes
- Don't parse Claude Code's stdout as a single JSON blob — it's newline-delimited, one event per line.
- Don't spawn a new Claude Code process without checking for an active session to resume.
- Don't watch node_modules or .git — always apply ignore patterns from sidecar config.
- Don't put Claude Code API keys anywhere in this codebase — auth is handled externally.
