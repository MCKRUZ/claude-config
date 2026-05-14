# PreCompact Hook - Save state before context compaction
# PowerShell version for Windows
#
# Runs before Claude compacts context, giving you a chance to
# preserve important state that might get lost in summarization.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "pre-compact" -MinProfile "minimal"
if ($script:HookSkipped) { exit 0 }

$SessionsDir = "$env:USERPROFILE\.claude\sessions"
$CompactionLog = Join-Path $SessionsDir "compaction-log.txt"

# Ensure sessions directory exists
if (-not (Test-Path $SessionsDir)) {
    New-Item -ItemType Directory -Path $SessionsDir -Force | Out-Null
}

# Log compaction event with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $CompactionLog -Value "[$timestamp] Context compaction triggered"

# If there's an active session file, note the compaction
$activeSessions = Get-ChildItem -Path $SessionsDir -Filter "*.tmp" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($activeSessions) {
    $activeSession = $activeSessions.FullName
    $currentTime = Get-Date -Format "HH:mm"
    Add-Content -Path $activeSession -Value ""
    Add-Content -Path $activeSession -Value "---"
    Add-Content -Path $activeSession -Value "**[Compaction occurred at $currentTime]** - Context was summarized"
}

Write-Host "[PreCompact] State saved before compaction" -ForegroundColor Cyan

