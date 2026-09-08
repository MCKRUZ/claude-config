# Strategic Compact Suggester
# PowerShell version for Windows
#
# Runs on PreToolUse to suggest manual compaction at logical intervals
#
# Why manual over auto-compact:
# - Auto-compact happens at arbitrary points, often mid-task
# - Strategic compacting preserves context through logical phases
# - Compact after exploration, before execution
# - Compact after completing a milestone, before starting next

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "suggest-compact" -MinProfile "standard"
if ($script:HookSkipped) { exit 0 }

# Use DEEP_SESSION_ID for session-scoped counting (survives across hook process spawns).
# Fall back to parent PID (the claude process) if session ID unavailable.
$sessionKey = $env:DEEP_SESSION_ID
if (-not $sessionKey) {
    try {
        $sessionKey = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID" -ErrorAction SilentlyContinue).ParentProcessId
    } catch {
        $sessionKey = "default"
    }
}
$CounterFile = "$env:TEMP\claude-tool-count-$sessionKey.txt"
$Threshold = if ($env:COMPACT_THRESHOLD) { [int]$env:COMPACT_THRESHOLD } else { 50 }

# Initialize or increment counter
$count = 1
if (Test-Path $CounterFile) {
    $count = [int](Get-Content $CounterFile) + 1
}
Set-Content -Path $CounterFile -Value $count

# Suggest compact after threshold tool calls
if ($count -eq $Threshold) {
    Write-Host "[StrategicCompact] $Threshold tool calls reached - consider /compact if transitioning phases" -ForegroundColor Yellow
}

# Suggest at regular intervals after threshold
if ($count -gt $Threshold -and ($count % 25) -eq 0) {
    Write-Host "[StrategicCompact] $count tool calls - good checkpoint for /compact if context is stale" -ForegroundColor Yellow
}

# Pass through stdin to stdout (required for hook chain)
$input | Write-Output
