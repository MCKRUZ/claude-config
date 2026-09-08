# Conventional Commits Hook — Validate commit message format
#
# PreToolUse on Bash: intercepts git commit commands and validates the message
# follows conventional commit format: type(scope): description

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "conventional-commits" -MinProfile "standard"
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
if ($command -notmatch 'git\s+commit') { exit 0 }
if ($command -match '--amend\b' -and $command -notmatch '-m\s') { exit 0 }

$commitMsg = $null
if ($command -match '-m\s+"([^"]+)"') {
    $commitMsg = $Matches[1]
} elseif ($command -match "-m\s+'([^']+)'") {
    $commitMsg = $Matches[1]
} else {
    # Handle HEREDOC format (cat <<'EOF' ... EOF) used by Claude Code
    $lines = $command -split "`n"
    $inHeredoc = $false
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '<<\s*[''"]?EOF') {
            $inHeredoc = $true
            continue
        }
        if ($inHeredoc) {
            if ($trimmed -eq 'EOF' -or $trimmed -match '^EOF\s*\)') { break }
            if ($trimmed -and $trimmed -notmatch 'Co-Authored-By' -and $trimmed -notmatch '^\)?"?\s*$') {
                $commitMsg = $trimmed
                break
            }
        }
    }
}

if (-not $commitMsg) { exit 0 }

$firstLine = ($commitMsg -split "`n")[0].Trim()

$validTypes = 'feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert'
$pattern = "^($validTypes)(\(.+\))?!?:\s.+"

if ($firstLine -notmatch $pattern) {
    Write-Error "BLOCKED: Commit message does not follow conventional commits format.
Expected: type(scope): description
Valid types: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert
Examples:
  feat: add user authentication
  fix(api): handle null response from payment service
  refactor(auth)!: remove deprecated OAuth1 flow
Got: '$firstLine'"
    exit 2
}

if ($firstLine.Length -gt 72) {
    Write-Host "[QualityGate] WARNING: Commit subject line is $($firstLine.Length) chars (recommended max: 72)." -ForegroundColor Yellow
}

exit 0
