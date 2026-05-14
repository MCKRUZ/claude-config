#!/bin/bash
# Auto-format files based on extension
# Receives JSON input via stdin from Claude Code hooks

# Hook profile gatekeeper (bash equivalent of hook-profile.ps1)
HOOK_ID="auto-format"
PROFILE="${CLAUDE_HOOK_PROFILE:-standard}"
DISABLED="${CLAUDE_DISABLED_HOOKS:-}"

# Check disabled list
if [[ ",$DISABLED," == *",$HOOK_ID,"* ]]; then exit 0; fi

# Profile check (this hook requires "standard" or higher)
case "$PROFILE" in
  minimal) exit 0 ;;
esac

# Add dotnet tools to PATH
export PATH="$PATH:/c/Users/kruz7/.dotnet/tools"

# Read JSON from stdin
input=$(cat)

# Extract file_path - handle potential JSON parse errors gracefully
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || {
    # Fallback: try to extract path with grep if jq fails
    file_path=$(echo "$input" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null) || exit 0
}

# Exit silently if no file path
if [ -z "$file_path" ]; then
    exit 0
fi

# Convert Windows path to Unix path for Git Bash if needed
unix_path=$(echo "$file_path" | sed 's|\\|/|g' | sed 's|^\([A-Za-z]\):|/\L\1|')

# Check if file exists
if [ ! -f "$unix_path" ] && [ ! -f "$file_path" ]; then
    exit 0
fi

# Use the path that exists
if [ -f "$unix_path" ]; then
    target_path="$unix_path"
else
    target_path="$file_path"
fi

# Format based on extension
case "$file_path" in
    *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.html|*.md)
        prettier --write "$target_path" 2>/dev/null || true
        ;;
    *.py)
        black "$target_path" 2>/dev/null || true
        ;;
    *.cs)
        csharpier "$target_path" 2>/dev/null || true
        ;;
    *.go)
        gofmt -w "$target_path" 2>/dev/null || true
        ;;
esac

exit 0

