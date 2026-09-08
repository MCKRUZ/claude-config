# Skill Switchboard — Event-Driven Skill Injection for Claude Code
# Fires on PreToolUse for Edit/Write tools.
# Reads the file path being edited, matches against rules.json, and injects
# relevant skill content into Claude's context before the tool executes.
#
# Pattern inspired by: Agent RuleZ (SpillwaveSolutions/agent_rulez)
# Architecture: file extension + directory AND-matching with priority ordering

param()

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "switchboard" -MinProfile "standard"
if ($script:HookSkipped) { exit 0 }

$RulesPath = "$PSScriptRoot\rules.json"
$MaxLinesDefault = 80

# --- Read hook input from stdin ---
$stdinRaw = $null
try {
    $stdinRaw = [Console]::In.ReadToEnd()
} catch {}

if (-not $stdinRaw) { exit 0 }

$hookData = $null
try {
    $hookData = $stdinRaw | ConvertFrom-Json
} catch {
    exit 0
}

# Extract file path from tool input
$filePath = $null
if ($hookData.tool_input.file_path) {
    $filePath = $hookData.tool_input.file_path
} elseif ($hookData.tool_input.path) {
    $filePath = $hookData.tool_input.path
}

if (-not $filePath) { exit 0 }

# Normalize to backslashes for consistent matching on Windows
$filePathNorm = $filePath.Replace('/', '\')
$fileExt = [System.IO.Path]::GetExtension($filePath).ToLower()

# --- Load rules ---
if (-not (Test-Path $RulesPath)) { exit 0 }

$rulesConfig = $null
try {
    $rulesConfig = Get-Content $RulesPath -Raw | ConvertFrom-Json
} catch {
    exit 0
}

# --- Path pattern matcher ---
# Supports: **/foo/** → path contains \foo\
#           **/foo    → path ends with \foo or contains \foo\
#           Exact patterns via -like
function Test-DirectoryPattern {
    param([string]$FilePath, [string]$Pattern)

    $Pattern = $Pattern.Replace('/', '\')

    # **/segment/** → file path contains \segment\
    if ($Pattern -match '^\*\*\\(.+)\\\*\*$') {
        $segment = $Matches[1]
        return ($FilePath -like "*\$segment\*") -or ($FilePath -like "*\$segment")
    }

    # **/segment → file path contains \segment as final component
    if ($Pattern -match '^\*\*\\(.+)$') {
        $segment = $Matches[1]
        # Handle extension patterns like **/*.Tests/**
        if ($segment -match '^\*\.(.+)') {
            $extPart = $Matches[1]
            return $FilePath -like "*.$extPart\*"
        }
        return ($FilePath -like "*\$segment\*") -or ($FilePath -like "*\$segment")
    }

    # Fallback: direct wildcard match
    return $FilePath -like $Pattern
}

# --- Match and collect triggered rules ---
$triggered = @()

foreach ($rule in $rulesConfig.rules) {
    if (-not $rule.enabled) { continue }
    if (-not $rule.inject_path) { continue }
    if (-not (Test-Path $rule.inject_path)) { continue }

    # Check extension match
    $extMatch = $false
    foreach ($ext in $rule.matchers.extensions) {
        if ($fileExt -eq $ext.ToLower()) {
            $extMatch = $true
            break
        }
    }
    if (-not $extMatch) { continue }

    # Check directory match (any one directory pattern must match)
    $dirMatch = $false
    foreach ($dirPattern in $rule.matchers.directories) {
        if (Test-DirectoryPattern -FilePath $filePathNorm -Pattern $dirPattern) {
            $dirMatch = $true
            break
        }
    }
    if (-not $dirMatch) { continue }

    $triggered += $rule
}

if ($triggered.Count -eq 0) { exit 0 }

# Sort by priority descending (higher priority injected first)
$triggered = $triggered | Sort-Object { $_.priority } -Descending

# --- Deduplicate by inject_path (avoid injecting same file twice) ---
$seen = @{}
$deduped = @()
foreach ($rule in $triggered) {
    $key = $rule.inject_path.ToLower()
    if (-not $seen.ContainsKey($key)) {
        $seen[$key] = $true
        $deduped += $rule
    }
}

# --- Output skill content ---
Write-Output ""
Write-Output "---"
Write-Output "## [SKILL SWITCHBOARD] Context injected for: $(Split-Path $filePath -Leaf)"
Write-Output ""

foreach ($rule in $deduped) {
    $maxLines = if ($rule.max_lines) { [int]$rule.max_lines } else { $MaxLinesDefault }

    try {
        $lines = Get-Content $rule.inject_path -ErrorAction Stop
        $truncated = $lines.Count -gt $maxLines
        $content = ($lines | Select-Object -First $maxLines) -join "`n"

        Write-Output "### Skill: $($rule.name)"
        Write-Output "_Source: $($rule.inject_path)_"
        Write-Output ""
        Write-Output $content
        if ($truncated) {
            Write-Output ""
            Write-Output "... [$($lines.Count - $maxLines) more lines — read full file at $($rule.inject_path)]"
        }
        Write-Output ""
    } catch {}
}

Write-Output "---"
Write-Output ""

exit 0
