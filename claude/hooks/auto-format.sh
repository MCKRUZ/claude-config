#!/bin/bash
# Auto-format files Claude edits — but ONLY in repos that have actually adopted the formatter.
# Receives JSON input via stdin from Claude Code hooks.
#
# Why the adoption test exists
# ----------------------------
# This hook used to run its formatter unconditionally. In a repo that never adopted that
# formatter, that turns every edit into a whole-file rewrite: a three-line change to
# claude-code-sdlc came back as 936 insertions / 243 deletions, because the repo is
# hand-written to ~100 columns and Black defaults to 88. Across that repo Black would have
# rewritten 64 of 69 files. A survey of 56 sibling repos found only 2 declaring a formatter
# at all, so "just run it" was reformatting code nobody asked it to touch.
#
# The decision, in order:
#   1. CLAUDE_FORMAT_MODE=off      -> never format.  =always -> old unconditional behaviour.
#   2. The repo DECLARES the formatter (a real config file / manifest entry) -> format.
#   3. The file's COMMITTED version is already formatter-clean -> format. This is what keeps
#      the hook useful in the many repos that use a formatter without configuring one: if the
#      file already complied before the edit, keeping it compliant is what the repo wants.
#   4. Otherwise -> do nothing. Never mass-rewrite a file that was not already compliant.
#
# Untracked/new files and non-git directories fall through to step 4 unless the repo declares
# the formatter, because there is no committed style to infer adoption from. Failing closed is
# deliberate: the cost of skipping a format is nil, the cost of an unrequested rewrite is a
# polluted diff on someone else's pull request.

HOOK_ID="auto-format"
PROFILE="${CLAUDE_HOOK_PROFILE:-standard}"
DISABLED="${CLAUDE_DISABLED_HOOKS:-}"
MODE="${CLAUDE_FORMAT_MODE:-adopted}"

if [[ ",$DISABLED," == *",$HOOK_ID,"* ]]; then exit 0; fi
case "$PROFILE" in
  minimal) exit 0 ;;
esac
[ "$MODE" = "off" ] && exit 0

export PATH="$PATH:/c/Users/kruz7/.dotnet/tools"

input=$(cat)

file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || {
    file_path=$(echo "$input" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null) || exit 0
}
[ -z "$file_path" ] && exit 0

unix_path=$(echo "$file_path" | sed 's|\\|/|g' | sed 's|^\([A-Za-z]\):|/\L\1|')
if [ -f "$unix_path" ]; then
    target_path="$unix_path"
elif [ -f "$file_path" ]; then
    target_path="$file_path"
else
    exit 0
fi

file_dir=$(dirname "$target_path")

# --- adoption signals -------------------------------------------------------------------------

# Walk from the file's directory up to the repo root looking for a marker. Bounded by the root
# so a stray config in a parent directory outside the project can never opt a repo in.
find_upward() {
    local dir="$1" root="$2" name
    while :; do
        for name in "${@:3}"; do
            if [ -e "$dir/$name" ]; then return 0; fi
        done
        [ "$dir" = "$root" ] && break
        local parent; parent=$(dirname "$dir")
        [ "$parent" = "$dir" ] && break
        dir="$parent"
    done
    return 1
}

# Same walk, but the marker is a string inside a file rather than the file's existence.
grep_upward() {
    local dir="$1" root="$2" file="$3" pattern="$4"
    while :; do
        if [ -f "$dir/$file" ] && grep -qi "$pattern" "$dir/$file" 2>/dev/null; then return 0; fi
        [ "$dir" = "$root" ] && break
        local parent; parent=$(dirname "$dir")
        [ "$parent" = "$dir" ] && break
        dir="$parent"
    done
    return 1
}

repo_root=$(git -C "$file_dir" rev-parse --show-toplevel 2>/dev/null)

# Does the repo declare this formatter?
repo_declares() {
    [ -z "$repo_root" ] && return 1
    case "$1" in
        prettier)
            find_upward "$file_dir" "$repo_root" \
                .prettierrc .prettierrc.json .prettierrc.yaml .prettierrc.yml \
                .prettierrc.js .prettierrc.cjs .prettierrc.mjs .prettierrc.toml \
                prettier.config.js prettier.config.cjs prettier.config.mjs && return 0
            grep_upward "$file_dir" "$repo_root" package.json '"prettier"' && return 0
            ;;
        black)
            grep_upward "$file_dir" "$repo_root" pyproject.toml '\[tool\.black\]' && return 0
            grep_upward "$file_dir" "$repo_root" .pre-commit-config.yaml 'black' && return 0
            ;;
        csharpier)
            find_upward "$file_dir" "$repo_root" \
                .csharpierrc .csharpierrc.json .csharpierrc.yaml .csharpierignore && return 0
            grep_upward "$file_dir" "$repo_root" .config/dotnet-tools.json 'csharpier' && return 0
            ;;
        gofmt)
            # Go has no formatter config — gofmt IS the convention. A go.mod is the adoption signal.
            find_upward "$file_dir" "$repo_root" go.mod && return 0
            ;;
    esac
    return 1
}

# Was the file already formatter-clean at HEAD, before Claude touched it?
committed_is_clean() {
    [ -z "$repo_root" ] && return 1
    local rel; rel=$(git -C "$repo_root" ls-files --full-name --error-unmatch "$target_path" 2>/dev/null) || return 1
    local blob; blob=$(git -C "$repo_root" show "HEAD:$rel" 2>/dev/null) || return 1
    [ -z "$blob" ] && return 1
    # `printf '%s\n'` restores the trailing newline that command substitution strips. Without it
    # every formatter reports "would reformat" (they all require a final newline) and no file
    # would ever look clean — the adoption test would silently never fire.
    case "$1" in
        prettier) printf '%s\n' "$blob" | prettier --check --stdin-filepath "$target_path" >/dev/null 2>&1 ;;
        black)    printf '%s\n' "$blob" | black --check --quiet - >/dev/null 2>&1 ;;
        gofmt)    [ -z "$(printf '%s\n' "$blob" | gofmt -l 2>/dev/null)" ] ;;
        # csharpier has no verified stdin check mode, so C# relies on declaration alone.
        *)        return 1 ;;
    esac
}

should_format() {
    [ "$MODE" = "always" ] && return 0
    repo_declares "$1" && return 0
    committed_is_clean "$1" && return 0
    return 1
}

# --- dispatch ---------------------------------------------------------------------------------

case "$file_path" in
    *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.html|*.md)
        should_format prettier && { prettier --write "$target_path" >/dev/null 2>&1 || true; }
        ;;
    *.py)
        should_format black && { black "$target_path" >/dev/null 2>&1 || true; }
        ;;
    *.cs)
        should_format csharpier && { csharpier "$target_path" >/dev/null 2>&1 || true; }
        ;;
    *.go)
        should_format gofmt && { gofmt -w "$target_path" >/dev/null 2>&1 || true; }
        ;;
esac

exit 0
