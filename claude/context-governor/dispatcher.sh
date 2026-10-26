#!/usr/bin/env bash
# Context Governor — StatusLine dispatcher.
#
# Claude Code allows exactly one statusLine.command. claude-hud owns the visible
# line. This dispatcher feeds the SAME status payload to both:
#   1. the governor's passive gauge logger (silent — writes JSONL only), and
#   2. claude-hud (produces the visible statusline on stdout, unchanged UX).
#
# The gauge logger is backgrounded and fully stdout/stderr-suppressed, so it can
# neither corrupt the statusline nor add latency. claude-hud resolution is copied
# verbatim from the original statusLine.command (highest installed version wins).
#
# This dispatcher is the one fragile coupling point (spec §3.4 / §6): it isolates
# every assumption about the StatusLine payload behind this single file.

NODE="/c/nvm4w/nodejs/node"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Consume stdin once; fan it out to both consumers.
input=$(cat)

# Gauge logger: fire-and-forget, fully silenced. Must never block or speak.
printf '%s' "$input" | "$NODE" "$CONFIG_DIR/context-governor/gauge-logger.mjs" >/dev/null 2>&1 &

# Jarvis: keep the subscription's rate-limit figures for the HUD. Same rules: silent, backgrounded.
printf '%s' "$input" | "$NODE" "/c/Users/kruz7/OneDrive/Documents/Code Repos/MCKRUZ/jarvis-os/app/packages/claude-code/tools/limits-tap.mjs" >/dev/null 2>&1 &

# claude-hud: the visible statusline. Resolve the highest installed version dir.
plugin_dir=$(ls -d "$CONFIG_DIR"/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null \
  | awk -F/ '{ print $(NF-1) "\t" $0 }' \
  | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
  | tail -1 | cut -f2-)

printf '%s' "$input" | "$NODE" "${plugin_dir}dist/index.js"
