# Block Find Hook — Block the `find` command entirely
#
# PreToolUse on Bash: blocks any invocation of find/find.exe (including Git Bash's
# usr\bin\find.exe). Incident 2026-09-08: an unscoped `find / -iname ...` run via
# Bash recursed into OneDrive's cloud-placeholder files and ran for hours across
# 7 processes, accumulating millions of open file handles and pinning CPU, which
# caused system-wide unresponsiveness (Chrome and keyboard input freezing).
# Use the Glob tool instead — it is scoped, fast, and does not touch OneDrive
# placeholders the way a raw filesystem walk does.
#
# To run find yourself despite this block, use `!find ...` at the prompt — that
# runs outside Claude's Bash tool and is not affected by this hook.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "block-find" -MinProfile "standard"
if ($script:HookSkipped) { exit 0 }

$input_json = $args[0]
if (-not $input_json) {
    $input_json = [Console]::In.ReadToEnd()
}

try {
    $data = $input_json | ConvertFrom-Json -ErrorAction Stop
    $command = $data.tool_input.command
} catch {
    exit 0
}

if (-not $command) { exit 0 }

# Matches `find` / `find.exe` (optionally path-prefixed, e.g. Git Bash's
# usr\bin\find.exe) as an invoked command: at the start of the command, or
# after a separator (;, &, |) or subshell open-paren. Does NOT match `find`
# appearing as an argument to another command (e.g. `grep -r find .`) or as
# a substring of another command name (e.g. `findstr`).
if ($command -match '(?im)(^|[;&|]\s*|\(\s*)(?:"[^"]*[\\/]|[^"\s;&|()]*[\\/])?find(\.exe)?"?(\s|$)') {
    Write-Error "BLOCKED: find is disabled after an incident where an unscoped find command ran for hours, exhausted file handles via OneDrive cloud placeholders, and froze the system. Use the Glob tool instead, e.g. Glob(**/Microsoft.Agents.AI*.dll). To run find yourself anyway, use an input-box bang command like: !find ..."
    exit 2
}

exit 0
