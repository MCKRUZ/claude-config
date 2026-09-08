# Destructive Command Safety Hook
#
# PreToolUse on Bash: blocks dangerous git operations (--no-verify, --force push,
# reset --hard, clean -f, branch -D main/master) AND other destructive commands
# (rm -rf, DROP/TRUNCATE SQL, kubectl delete, docker prune, chmod 777, dd).

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "git-safety" -MinProfile "standard"
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

$blocked = $false
$reason = ""

# --- Git safety checks ---

if ($command -match 'git\s+(commit|push)\s.*--no-verify') {
    $blocked = $true
    $reason = "BLOCKED: --no-verify bypasses pre-commit hooks. Fix the underlying issue instead."
}

if ($command -match 'git\s+push\s.*--force(?!-)' -or $command -match 'git\s+push\s.*-f\b') {
    $blocked = $true
    $reason = "BLOCKED: Force push can destroy remote history. Use --force-with-lease if necessary, or ask the user."
}

if ($command -match 'git\s+reset\s+--hard') {
    $blocked = $true
    $reason = "BLOCKED: git reset --hard discards uncommitted changes. Confirm with the user first."
}

if ($command -match 'git\s+clean\s+-[a-zA-Z]*f') {
    $blocked = $true
    $reason = "BLOCKED: git clean -f permanently deletes untracked files. Confirm with the user first."
}

if ($command -match 'git\s+branch\s+-[dD]\s+(main|master)\b') {
    $blocked = $true
    $reason = "BLOCKED: Cannot delete main/master branch."
}

# --- Destructive command checks ---

$safeRmTargets = '(node_modules|\.next|dist|__pycache__|\.cache|build|\.turbo|coverage|\.angular|out|\.parcel-cache|tmp)'
if ($command -match 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+|--recursive\s+)') {
    if ($command -notmatch "rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+|--recursive\s+)(\./)?$safeRmTargets(/?\s*$|\s)") {
        $blocked = $true
        $reason = "BLOCKED: Recursive delete targets something other than safe build artifacts. Confirm with the user first."
    }
}

if ($command -match '(?i)\b(DROP\s+(TABLE|DATABASE)|TRUNCATE)\b') {
    $blocked = $true
    $reason = "BLOCKED: SQL data destruction (DROP/TRUNCATE) detected. Confirm with the user first."
}

if ($command -match 'kubectl\s+delete\b') {
    $blocked = $true
    $reason = "BLOCKED: kubectl delete can destroy production resources. Confirm with the user first."
}

if ($command -match 'docker\s+(rm\s+-[a-zA-Z]*f|system\s+prune|volume\s+prune)') {
    $blocked = $true
    $reason = "BLOCKED: Docker destructive operation detected. Confirm with the user first."
}

if ($command -match 'chmod\s+(-R\s+)?777\b') {
    $blocked = $true
    $reason = "BLOCKED: chmod 777 removes all file permission restrictions. Use specific permissions instead."
}

if ($command -match '\bdd\s+if=') {
    $blocked = $true
    $reason = "BLOCKED: dd can overwrite disks and destroy data. Confirm with the user first."
}

if ($blocked) {
    Write-Error $reason
    exit 2
}

exit 0
